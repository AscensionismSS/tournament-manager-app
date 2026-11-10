import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/tournament_events_service.dart';
import '../../../core/network/tournament_webhook_event_dto.dart';
import '../../../core/services/system_security_service.dart';
import '../../../core/storage/token_storage.dart';
import '../models/tournament_dto.dart';
import '../models/tournament_status.dart';
import '../models/match_series_dto.dart';
import '../models/tournament_standings_dto.dart';
import '../../draft/models/draft_state_snapshot_dto.dart';

/// Abas da página interna de um Campeonato com seus respectivos slugs de rota no GoRouter
enum TournamentDetailTab {
  overview('overview', 'Visão Geral', Icons.dashboard_customize_rounded),
  playerPool('pool', 'Pool de Jogadores', Icons.person_search_rounded),
  draft('draft', 'Draft & Gestão de Times', Icons.shuffle_rounded),
  teams('teams', 'Equipes', Icons.groups_rounded),
  groupStage('groups', 'Tabela de Grupos', Icons.grid_view_rounded),
  matches('matches', 'Partidas de Grupos', Icons.sports_esports_rounded),
  playoffs('playoffs', 'Playoffs', Icons.account_tree_rounded);

  final String slug;
  final String label;
  final IconData icon;
  const TournamentDetailTab(this.slug, this.label, this.icon);

  /// Resolve a aba a partir do segmento `:tab` da URL (`/tournaments/:id/:tab`)
  static TournamentDetailTab fromSlug(String? rawSlug) {
    final clean = rawSlug?.trim().toLowerCase();
    for (final tab in TournamentDetailTab.values) {
      if (tab.slug == clean) return tab;
    }
    return TournamentDetailTab.overview;
  }
}

/// Modelo pronto de um Grupo para renderização passiva na View (Dumb UI).
class TournamentGroupTableData {
  final String title;
  final String groupCode;
  final List<TeamStandingDto> rows;
  final List<MatchSeriesDto> matches;

  const TournamentGroupTableData({
    required this.title,
    required this.groupCode,
    required this.rows,
    required this.matches,
  });
}

/// Controller da página de detalhes do Campeonato (`/tournaments/:id`).
/// Orquestra a busca do campeonato, classificação de grupos, partidas e ações rápidas.
class TournamentDetailsController extends ChangeNotifier {
  final String tournamentId;

  TournamentDto? _tournament;
  TournamentDto? get tournament => _tournament;

  List<TeamStandingDto> _standings = [];
  List<TeamStandingDto> get standings => _standings;

  List<MatchSeriesDto> _matches = [];
  List<MatchSeriesDto> get matches => _matches;

  DraftStateSnapshotDto? _draftSnapshot;
  DraftStateSnapshotDto? get draftSnapshot => _draftSnapshot;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmittingAction = false;
  bool get isSubmittingAction => _isSubmittingAction;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  TournamentDetailTab _activeTab;
  TournamentDetailTab get activeTab => _activeTab;

  StreamSubscription<TournamentWebhookEventDto>? _sseSubscription;

  TournamentDetailsController({
    required this.tournamentId,
    TournamentDto? initialTournament,
    TournamentDetailTab initialTab = TournamentDetailTab.overview,
  })  : _tournament = initialTournament,
        _activeTab = initialTab {
    _startRealTimeEvents();
  }

  bool _isDisposed = false;

  void _startRealTimeEvents() {
    _sseSubscription = TournamentEventsService.instance
        .subscribeToTournament(tournamentId)
        .listen((_) {
      fetchTournament(silent: true);
    });
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _sseSubscription?.cancel();
    super.dispose();
  }

  /// Lista as abas visíveis conforme o formato do campeonato e permissões de Admin (oculta Grupos se Mata-Mata Direto)
  List<TournamentDetailTab> visibleTabsFor({required bool canManage}) {
    final t = _tournament;
    final List<TournamentDetailTab> tabs = [TournamentDetailTab.overview];
    if (t != null && t.hasDraftSession) {
      tabs.add(TournamentDetailTab.playerPool);
    }
    tabs.add(TournamentDetailTab.teams);
    if (t == null || t.hasGroupStage) {
      tabs.add(TournamentDetailTab.groupStage);
      tabs.add(TournamentDetailTab.matches);
    }
    tabs.add(TournamentDetailTab.playoffs);

    // Aba de Sala de Draft / Gestão de Equipe:
    // Se o draft já foi concluído (isCompleted), ela só fica visível se canManage for true (exclusivo para Admin).
    // Para jogadores comuns pós-draft, a gestão fica oculta e eles veem apenas as Equipes em modo somente-leitura.
    final isDraftCompleted = _draftSnapshot?.isCompleted ?? false;
    final canShowDraftTab = t != null &&
        t.hasDraftSession &&
        t.status != TournamentStatus.completed &&
        t.status != TournamentStatus.canceled &&
        (!isDraftCompleted || canManage);

    if (canShowDraftTab) {
      tabs.add(TournamentDetailTab.draft);
    }

    return tabs;
  }

  List<TournamentDetailTab> get visibleTabs => visibleTabsFor(
        canManage:
            TokenStorage.profileNotifier.value?.canManageTournaments ?? false,
      );

  void setActiveTab(TournamentDetailTab tab) {
    if (_activeTab != tab) {
      _activeTab = tab;
      notifyListeners();
    }
  }

  /// Indica se todas as partidas da Fase de Grupos foram concluídas e o torneio está pronto para avançar aos Playoffs.
  bool get canAdvanceToPlayoffs {
    final t = _tournament;
    if (t == null || t.status != TournamentStatus.groupStage) return false;
    final groupMatches = _matches.where((m) => m.isGroupStageMatch).toList();
    return groupMatches.isNotEmpty && groupMatches.every((m) => m.isCompleted);
  }

  /// Texto de progresso das partidas da Fase de Grupos (ex: "21/21 Partidas Concluídas")
  String get groupStageProgressLabel {
    final groupMatches = _matches.where((m) => m.isGroupStageMatch).toList();
    final completed = groupMatches.where((m) => m.isCompleted).length;
    return '$completed/${groupMatches.length} Partidas Concluídas';
  }

  /// Monta as tabelas de grupos prontas para a View (suportando 0 times com placeholders ou dados reais da API)
  List<TournamentGroupTableData> get groupTables {
    final t = _tournament;
    if (t == null || !t.hasGroupStage) return const [];

    final groupMatches = _matches.where((m) => m.isGroupStageMatch).toList();

    if (t.groupCount == 2) {
      final hasServerGroupCodes = _standings.any(
        (s) => s.groupCode != null && s.groupCode!.trim().isNotEmpty,
      );

      final Set<String> groupATeamIds;
      final Set<String> groupBTeamIds;
      final List<String> fallbackTeamsA;
      final List<String> fallbackTeamsB;

      if (hasServerGroupCodes) {
        groupATeamIds = _standings
            .where((s) => (s.groupCode ?? '').toUpperCase().contains('A'))
            .map((e) => e.teamId)
            .where((id) => id.isNotEmpty)
            .toSet();
        groupBTeamIds = _standings
            .where((s) => (s.groupCode ?? '').toUpperCase().contains('B'))
            .map((e) => e.teamId)
            .where((id) => id.isNotEmpty)
            .toSet();

        final explicitA = t.teams.where((team) => groupATeamIds.contains(team.id)).map((e) => e.name).toList();
        final explicitB = t.teams.where((team) => groupBTeamIds.contains(team.id)).map((e) => e.name).toList();

        fallbackTeamsA = explicitA.isNotEmpty
            ? explicitA
            : t.teams.take(t.teamsPerGroup).map((e) => e.name).toList();
        fallbackTeamsB = explicitB.isNotEmpty
            ? explicitB
            : t.teams.skip(t.teamsPerGroup).take(t.teamsPerGroup).map((e) => e.name).toList();
      } else {
        groupATeamIds = t.teams.take(t.teamsPerGroup).map((e) => e.id).toSet();
        groupBTeamIds = t.teams.skip(t.teamsPerGroup).take(t.teamsPerGroup).map((e) => e.id).toSet();
        fallbackTeamsA = t.teams.take(t.teamsPerGroup).map((e) => e.name).toList();
        fallbackTeamsB = t.teams.skip(t.teamsPerGroup).take(t.teamsPerGroup).map((e) => e.name).toList();
      }

      final rowsA = _buildGroupRows(
        groupCode: 'A',
        capacity: t.teamsPerGroup,
        teamIdsFilter: groupATeamIds,
        fallbackTeams: fallbackTeamsA,
      );
      final rowsB = _buildGroupRows(
        groupCode: 'B',
        capacity: t.teamsPerGroup,
        teamIdsFilter: groupBTeamIds,
        fallbackTeams: fallbackTeamsB,
      );

      return [
        TournamentGroupTableData(
          title: 'GRUPO A',
          groupCode: 'A',
          rows: rowsA,
          matches: groupMatches.where((m) => m.isGroupAMatch).toList(),
        ),
        TournamentGroupTableData(
          title: 'GRUPO B',
          groupCode: 'B',
          rows: rowsB,
          matches: groupMatches.where((m) => m.isGroupBMatch).toList(),
        ),
      ];
    }

    final rowsSingle = _buildGroupRows(
      groupCode: 'G',
      capacity: t.teamCount,
      teamIdsFilter: t.teams.map((e) => e.id).toSet(),
      fallbackTeams: t.teams.map((e) => e.name).toList(),
    );

    return [
      TournamentGroupTableData(
        title: 'GRUPO ÚNICO — CLASSIFICAÇÃO GERAL',
        groupCode: 'G',
        rows: rowsSingle,
        matches: groupMatches,
      ),
    ];
  }

  List<TeamStandingDto> _buildGroupRows({
    required String groupCode,
    required int capacity,
    required Set<String> teamIdsFilter,
    required List<String> fallbackTeams,
  }) {
    final matchedStandings = _standings.where((s) {
      if (s.groupCode != null && s.groupCode!.isNotEmpty) {
        return s.groupCode!.toUpperCase().contains(groupCode);
      }
      return teamIdsFilter.contains(s.teamId);
    }).toList();

    final result = <TeamStandingDto>[];
    for (int i = 0; i < capacity; i++) {
      if (i < matchedStandings.length) {
        final s = matchedStandings[i];
        result.add(TeamStandingDto(
          rank: i + 1,
          teamId: s.teamId,
          teamName: s.teamName,
          groupCode: groupCode,
          points: s.points,
          playedMatches: s.playedMatches,
          wonMatches: s.wonMatches,
          drawnMatches: s.drawnMatches,
          lostMatches: s.lostMatches,
          mapWins: s.mapWins,
          mapLosses: s.mapLosses,
          mapDifferential: s.mapDifferential,
          totalVictoryDurationSeconds: s.totalVictoryDurationSeconds,
          totalKills: s.totalKills,
          totalDeaths: s.totalDeaths,
          killDifferential: s.killDifferential,
        ));
      } else {
        final registeredName = i < fallbackTeams.length ? fallbackTeams[i] : null;
        result.add(TeamStandingDto.placeholder(
          rank: i + 1,
          teamName: registeredName,
          groupCode: groupCode,
        ));
      }
    }
    return result;
  }

  /// Busca campeonato, tabela de grupos e partidas em paralelo
  Future<void> fetchTournament({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.tournamentById(tournamentId),
        requiresAuth: true,
      );
      final raw = responseJson['data'] is Map<String, dynamic>
          ? responseJson['data'] as Map<String, dynamic>
          : responseJson;
      _tournament = TournamentDto.fromJson(raw);

      if (!_tournament!.hasGroupStage &&
          (_activeTab == TournamentDetailTab.groupStage ||
              _activeTab == TournamentDetailTab.matches)) {
        _activeTab = TournamentDetailTab.overview;
      }

      await Future.wait([
        _fetchStandingsSilently(),
        _fetchMatchesSilently(),
        _fetchDraftSnapshotSilently(),
      ]);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Não foi possível carregar os dados do campeonato: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchStandingsSilently() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.tournamentStandings(tournamentId),
        requiresAuth: true,
      );
      final rawList = res['standings'] ?? res['data'] ?? res['items'];
      if (rawList is List) {
        _standings = rawList
            .whereType<Map<String, dynamic>>()
            .map(TeamStandingDto.fromJson)
            .toList();
      }
    } catch (_) {
      _standings = [];
    }
  }

  Future<void> _fetchMatchesSilently() async {
    try {
      final res = await ApiClient.get(
        ApiEndpoints.tournamentMatches(tournamentId),
        requiresAuth: true,
      );
      final rawList = res['data'] ?? res['items'] ?? res;
      if (rawList is List) {
        _matches = rawList
            .whereType<Map<String, dynamic>>()
            .map(MatchSeriesDto.fromJson)
            .toList();
      }
    } catch (_) {
      _matches = [];
    }
  }

  Future<void> _fetchDraftSnapshotSilently() async {
    final sessionId = _tournament?.draftSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _draftSnapshot = null;
      return;
    }

    try {
      final res = await ApiClient.get(
        ApiEndpoints.draftSnapshot(sessionId),
        requiresAuth: true,
      );
      _draftSnapshot = DraftStateSnapshotDto.fromJson(res);
    } catch (_) {
      _draftSnapshot = null;
    }
  }

  /// Renomeia uma equipe no backend (sincroniza na sessão de draft e no campeonato)
  Future<String?> renameTeam(String teamId, String newName) async {
    final sessionId = _tournament?.draftSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return 'Nenhuma sessão de draft vinculada a este campeonato.';
    }

    _isSubmittingAction = true;
    notifyListeners();

    try {
      final expectedVersion = _draftSnapshot?.draftVersion ?? 1;
      await ApiClient.post(
        ApiEndpoints.draftRenameTeam(sessionId),
        body: {
          'teamId': teamId,
          'newName': newName.trim(),
          'expectedVersion': expectedVersion,
        },
        requiresAuth: true,
      );

      // Recarrega os dados do torneio e o snapshot em silêncio
      await fetchTournament(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao renomear equipe: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> openRegistrations() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentOpenRegistrations(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao abrir inscrições: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> closeRegistrations() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentCloseRegistrations(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao fechar inscrições: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  /// Inscreve o usuário autenticado no pool de draft do campeonato
  Future<String?> registerCurrentPlayerToDraft() async {
    final sessionId = _tournament?.draftSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return 'Sessão de draft não encontrada para este campeonato.';
    }

    final user = await TokenStorage.getUserProfile();
    if (user == null) {
      return 'Você precisa estar autenticado para se inscrever.';
    }

    _isSubmittingAction = true;
    notifyListeners();

    try {
      final name = user.dotaPersonaName?.trim().isNotEmpty == true
          ? user.dotaPersonaName!.trim()
          : user.displayName.trim();

      final body = {
        'name': name.isNotEmpty ? name : user.email.split('@').first,
        'externalUserId': user.steamId,
        'roles': user.roles,
        'preferredRole': user.preferredRole,
        'rankTier': int.tryParse(user.dotaRankTier ?? ''),
        'avatarUrl': user.dotaAvatarUrl,
      };

      await ApiClient.post(
        ApiEndpoints.draftPool(sessionId),
        body: body,
        requiresAuth: true,
      );

      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao se inscrever no pool: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  /// Cancela a inscrição do usuário autenticado no pool de draft (se ainda não draftado)
  Future<String?> removeCurrentPlayerFromDraftPool() async {
    final sessionId = _tournament?.draftSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      return 'Sessão de draft não encontrada.';
    }

    final user = await TokenStorage.getUserProfile();
    if (user == null) return 'Usuário não autenticado.';

    _isSubmittingAction = true;
    notifyListeners();

    try {
      final pool = _tournament?.draftPlayerPool ?? [];
      final player = pool.firstWhere(
        (p) =>
            p.id == user.userId ||
            (p.externalUserId != null &&
                user.steamId != null &&
                p.externalUserId == user.steamId),
        orElse: () => throw Exception('Inscrição não encontrada no pool deste campeonato.'),
      );

      final url = '${ApiEndpoints.draftPool(sessionId)}/${player.id}';
      await ApiClient.delete(url, requiresAuth: true);

      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao cancelar inscrição: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> lockResultSubmission(String reason) async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      final res = await ApiClient.post(
        ApiEndpoints.tournamentLockResults(tournamentId),
        body: {'reason': reason.trim().isEmpty ? null : reason.trim()},
        requiresAuth: true,
      );
      _tournament = TournamentDto.fromJson(res);
      await fetchTournament(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao travar envio de resultados: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> unlockResultSubmission() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      final res = await ApiClient.post(
        ApiEndpoints.tournamentUnlockResults(tournamentId),
        requiresAuth: true,
      );
      _tournament = TournamentDto.fromJson(res);
      await fetchTournament(silent: true);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao destravar envio de resultados: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> addTeam(String teamName) async {
    if (SystemSecurityService.instance.isTournamentRegistrationLocked) {
      final msg = SystemSecurityService.instance.message;
      return (msg != null && msg.trim().isNotEmpty)
          ? msg.trim()
          : 'As inscrições de torneios estão temporariamente bloqueadas pela administração do sistema.';
    }

    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentTeams(tournamentId),
        body: {'teamName': teamName.trim()},
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao inscrever equipe: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> startTournament() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentStart(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao iniciar o campeonato: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> advanceToPlayoffs() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentAdvanceToPlayoffs(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao gerar os playoffs: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> revertToGroupStage() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentRevertToGroupStage(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao reverter para a fase de grupos: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> cancelTournament() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.post(
        ApiEndpoints.tournamentCancel(tournamentId),
        requiresAuth: true,
      );
      await fetchTournament();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao cancelar o campeonato: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }

  Future<String?> deleteTournament() async {
    _isSubmittingAction = true;
    notifyListeners();
    try {
      await ApiClient.delete(
        ApiEndpoints.tournamentById(tournamentId),
        requiresAuth: true,
      );
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erro ao excluir o campeonato: $e';
    } finally {
      _isSubmittingAction = false;
      notifyListeners();
    }
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/shared_widgets/app_select_box.dart';
import '../../../core/theme/theme.dart';
import '../models/pro_matches_dto.dart';

/// Filtros rápidos de nível/status disponíveis na tela do Cenário Pro.
enum ProMatchFilter {
  all('Todos os Níveis'),
  major('Major (Tier S)'),
  tierA('Pro Tier A'),
  live('Ao Vivo Agora');

  final String label;
  const ProMatchFilter(this.label);

  static const List<AppSelectOption<ProMatchFilter>> selectOptions = [
    AppSelectOption(
      value: ProMatchFilter.all,
      label: 'Todos os Níveis',
      iconWidget: Icon(Icons.public_rounded, size: 17, color: AppColors.dotaGold),
    ),
    AppSelectOption(
      value: ProMatchFilter.major,
      label: 'Major (Tier S)',
      iconWidget: Icon(
        Icons.workspace_premium_rounded,
        size: 17,
        color: AppColors.proTierMajor,
      ),
    ),
    AppSelectOption(
      value: ProMatchFilter.tierA,
      label: 'Pro Tier A',
      iconWidget: Icon(
        Icons.emoji_events_outlined,
        size: 17,
        color: AppColors.proTierA,
      ),
    ),
    AppSelectOption(
      value: ProMatchFilter.live,
      label: 'Ao Vivo Agora',
      iconWidget: Icon(
        Icons.sensors_rounded,
        size: 17,
        color: AppColors.primaryNeon,
      ),
    ),
  ];
}

/// Controller da feature `pro_matches` (SRP).
/// Orquestra requisições à API `/pro-matches`, busca textual, filtro por nível e
/// por campeonato, cooldown anti-flood no botão Atualizar e ciclo de vida seguro.
class ProMatchesController extends ChangeNotifier {
  static const int refreshCooldownSeconds = 30;

  final TextEditingController searchController = TextEditingController();

  ProMatchesOverviewDto? _overview;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  ProMatchFilter _activeFilter = ProMatchFilter.all;
  String? _selectedLeagueName;
  String _searchQuery = '';
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  bool _isDisposed = false;

  ProMatchesOverviewDto? get overview => _overview;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  ProMatchFilter get activeFilter => _activeFilter;
  String? get selectedLeagueName => _selectedLeagueName;
  String get searchQuery => _searchQuery;
  int get cooldownRemaining => _cooldownRemaining;

  bool get isOnCooldown => _cooldownRemaining > 0;
  bool get canRefresh => !_isLoading && !_isRefreshing && !isOnCooldown;
  bool get isConfigured => _overview?.isConfigured ?? true;
  bool get hasData => _overview != null;

  bool get hasActiveFilters =>
      _activeFilter != ProMatchFilter.all ||
      _selectedLeagueName != null ||
      _searchQuery.isNotEmpty;

  String get refreshButtonLabel =>
      isOnCooldown ? 'Aguarde ${_cooldownRemaining}s' : 'Atualizar';

  /// Opções dinâmicas para o filtro de Campeonato/Liga ([AppSelectBox]),
  /// agrupadas por nome da liga sem repetir divisões de chaves/grupos (ex: BLAST Slam uma única vez).
  List<AppSelectOption<String?>> get tournamentFilterOptions {
    final tournaments = _overview?.tournaments ?? const <ProTournamentGroupDto>[];
    final seenLeagues = <String, ProTournamentGroupDto>{};

    for (final t in tournaments) {
      final league = (t.leagueName.isNotEmpty ? t.leagueName : t.name).trim();
      final key = league.toLowerCase();
      seenLeagues.putIfAbsent(key, () => t);
    }

    return [
      const AppSelectOption<String?>(
        value: null,
        label: 'Todos os Campeonatos',
        iconWidget: Icon(
          Icons.emoji_events_rounded,
          size: 17,
          color: AppColors.primaryNeon,
        ),
      ),
      ...seenLeagues.values.map((t) {
        final leagueLabel =
            (t.leagueName.isNotEmpty ? t.leagueName : t.name).trim();
        return AppSelectOption<String?>(
          value: leagueLabel,
          label: leagueLabel,
          iconWidget: Icon(
            t.tierIcon,
            size: 16,
            color: t.tierColor,
          ),
        );
      }),
    ];
  }

  /// Retorna os campeonatos filtrados combinando nível, liga selecionada e busca.
  List<ProTournamentGroupDto> get filteredTournaments {
    final tournaments = _overview?.tournaments ?? const <ProTournamentGroupDto>[];
    final query = _searchQuery.trim().toLowerCase();

    return tournaments.where((t) {
      if (_selectedLeagueName != null) {
        final leagueLabel =
            (t.leagueName.isNotEmpty ? t.leagueName : t.name).trim();
        if (leagueLabel.toLowerCase() != _selectedLeagueName!.toLowerCase()) {
          return false;
        }
      }

      switch (_activeFilter) {
        case ProMatchFilter.all:
          break;
        case ProMatchFilter.major:
          if (!t.isMajor) return false;
          break;
        case ProMatchFilter.tierA:
          if (t.isMajor) return false;
          break;
        case ProMatchFilter.live:
          if (t.liveMatches.isEmpty) return false;
          break;
      }

      if (query.isNotEmpty) {
        final matchesTournament = t.name.toLowerCase().contains(query) ||
            t.leagueName.toLowerCase().contains(query);
        final matchesAnyTeam = t.liveMatches.any((m) => _matchContainsQuery(m, query)) ||
            t.upcomingMatches.any((m) => _matchContainsQuery(m, query));
        if (!matchesTournament && !matchesAnyTeam) return false;
      }

      return true;
    }).toList(growable: false);
  }

  bool _matchContainsQuery(ProMatchDto match, String query) {
    return match.teamA.name.toLowerCase().contains(query) ||
        match.teamA.acronym.toLowerCase().contains(query) ||
        match.teamB.name.toLowerCase().contains(query) ||
        match.teamB.acronym.toLowerCase().contains(query);
  }

  /// Carrega ou atualiza os dados do backend com proteção anti-flood para refresh manual.
  Future<void> fetchOverview({bool force = false}) async {
    if (_isLoading || _isRefreshing) return;
    if (force && isOnCooldown) return;
    if (!force && _overview != null) return;

    final hasExisting = _overview != null;
    if (hasExisting) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await ApiClient.get(
        ApiEndpoints.proMatchesOverview,
        requiresAuth: true,
      );
      _overview = ProMatchesOverviewDto.fromJson(response);

      // Se a liga selecionada não existe mais no novo snapshot, reseta filtro
      if (_selectedLeagueName != null &&
          !(_overview?.tournaments.any((t) {
                final leagueLabel =
                    (t.leagueName.isNotEmpty ? t.leagueName : t.name).trim();
                return leagueLabel.toLowerCase() ==
                    _selectedLeagueName!.toLowerCase();
              }) ??
              false)) {
        _selectedLeagueName = null;
      }

      if (force) {
        _startRefreshCooldown();
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os jogos do cenário profissional.';
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      _safeNotify();
    }
  }

  void _startRefreshCooldown() {
    _cooldownTimer?.cancel();
    _cooldownRemaining = refreshCooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      if (_cooldownRemaining <= 1) {
        _cooldownRemaining = 0;
        timer.cancel();
      } else {
        _cooldownRemaining--;
      }
      _safeNotify();
    });
  }

  void setFilter(ProMatchFilter? filter) {
    final next = filter ?? ProMatchFilter.all;
    if (_activeFilter == next) return;
    _activeFilter = next;
    _safeNotify();
  }

  void setLeagueFilter(String? leagueName) {
    if (_selectedLeagueName == leagueName) return;
    _selectedLeagueName = leagueName;
    _safeNotify();
  }

  void onSearchSubmitted(String query) {
    final clean = query.trim();
    if (_searchQuery == clean) return;
    _searchQuery = clean;
    _safeNotify();
  }

  void clearFilters() {
    if (!hasActiveFilters) return;
    _activeFilter = ProMatchFilter.all;
    _selectedLeagueName = null;
    _searchQuery = '';
    searchController.clear();
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cooldownTimer?.cancel();
    searchController.dispose();
    _overview = null;
    super.dispose();
  }
}

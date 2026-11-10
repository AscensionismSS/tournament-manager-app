import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../../auth/models/steam_preview_dto.dart';
import '../../../members/models/member_dto.dart';

/// Modal oficial para buscar e adicionar membros da comunidade na pool do Draft (SRP & Dumb UI).
/// Exige 100% de correspondência no Nick ou SteamID para seleção direta no card.
/// Utiliza estritamente o [SteamPreviewCard] oficial do shared para exibir a prévia verificada da Steam
/// e validação obrigatória de vínculo com Steam, funções (Roles) e duplicidade na sessão de draft.
class AddLatePlayerDialog extends StatefulWidget {
  final Set<String> existingIdentifiers;
  final Future<String?> Function({
    required String name,
    required String playerId,
    required List<String> roles,
    required String preferredRole,
    int? rankTier,
    String? avatarUrl,
  }) onAdd;

  const AddLatePlayerDialog({
    super.key,
    required this.onAdd,
    this.existingIdentifiers = const {},
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<String?> Function({
      required String name,
      required String playerId,
      required List<String> roles,
      required String preferredRole,
      int? rankTier,
      String? avatarUrl,
    }) onAdd,
    Set<String> existingIdentifiers = const {},
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AppDialog(
        title: 'ADICIONAR JOGADOR À POOL',
        icon: Icons.person_add_alt_1_rounded,
        iconColor: AppColors.dotaGold,
        maxWidth: 480,
        content: AddLatePlayerDialog(
          onAdd: onAdd,
          existingIdentifiers: existingIdentifiers,
        ),
      ),
    );
  }

  @override
  State<AddLatePlayerDialog> createState() => _AddLatePlayerDialogState();
}

class _AddLatePlayerDialogState extends State<AddLatePlayerDialog> {
  late final TextEditingController _searchController;

  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _customHeaderLabel;

  MemberDto? _selectedMember;
  SteamPreviewDto? _steamPreview;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeSearchQuery(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return '';

    final profileMatch = RegExp(r'profiles/(\d+)').firstMatch(clean);
    if (profileMatch != null) return profileMatch.group(1)!;

    final vanityMatch = RegExp(r'id/([^/?#]+)').firstMatch(clean);
    if (vanityMatch != null) return vanityMatch.group(1)!;

    return clean;
  }

  bool _isMemberAlreadyInDraft(MemberDto member) {
    if (widget.existingIdentifiers.isEmpty) return false;
    final uid = member.userId.toLowerCase();
    final name = member.effectiveNickname.toLowerCase();
    final dName = member.displayName.toLowerCase();
    final pName = member.personaName?.toLowerCase();
    final sid = member.steamId?.toLowerCase();

    return widget.existingIdentifiers.contains(uid) ||
        widget.existingIdentifiers.contains(name) ||
        widget.existingIdentifiers.contains(dName) ||
        (pName != null && widget.existingIdentifiers.contains(pName)) ||
        (sid != null && widget.existingIdentifiers.contains(sid));
  }

  SteamPreviewDto _createSteamPreview(
    MemberDto member, {
    required bool isAlreadyInUse,
  }) {
    return SteamPreviewDto(
      steamId: member.steamId ?? '',
      personaName: member.effectiveNickname,
      avatarUrl: member.avatarUrl,
      rankTier: member.rankTier,
      leaderboardRank: member.leaderboardRank,
      profileUrl: member.computedSteamProfileUrl,
      steamIdString: member.steamId,
      isAlreadyInUse: isAlreadyInUse,
    );
  }

  void _onSearchChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _selectedMember = null;
        _steamPreview = null;
        _errorMessage = null;
        _customHeaderLabel = null;
      });
    } else {
      // Apenas atualiza a UI para exibir o botão de limpar (X)
      // ZERO requisições de rede ao digitar - economia total de tráfego
      setState(() {});
    }
  }

  void _handleManualSearch() {
    if (_isSearching) return;
    final query = _normalizeSearchQuery(_searchController.text);
    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Digite o nick exato ou link/ID da Steam.';
        _customHeaderLabel = null;
      });
      return;
    }
    _executeSearch(query);
  }

  Future<void> _executeSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final endpoint = ApiEndpoints.members(search: query);
      final responseJson = await ApiClient.get(endpoint, requiresAuth: true);

      final rawData = responseJson['data'] ??
          responseJson['items'] ??
          responseJson['users'] ??
          responseJson['members'] ??
          (responseJson is List ? responseJson : const <dynamic>[]);

      final List<dynamic> listData = rawData is List ? rawData : const <dynamic>[];

      final results = listData
          .map((item) => MemberDto.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;

      // Correspondência estrita de 100% de caracteres no nick ou SteamID
      final qLower = query.trim().toLowerCase();
      MemberDto? exactMatch;

      for (final m in results) {
        final dName = m.displayName.trim().toLowerCase();
        final pName = m.personaName?.trim().toLowerCase();
        final eNick = m.effectiveNickname.trim().toLowerCase();
        final sId = m.steamId?.trim().toLowerCase();
        final uId = m.userId.trim().toLowerCase();

        if (dName == qLower ||
            (pName != null && pName == qLower) ||
            eNick == qLower ||
            (sId != null && sId == qLower) ||
            uId == qLower) {
          exactMatch = m;
          break;
        }
      }

      if (exactMatch == null) {
        setState(() {
          _isSearching = false;
          _selectedMember = null;
          _steamPreview = null;
          _customHeaderLabel = null;
          _errorMessage =
              'Nenhum membro encontrado com este nick ou SteamID exato.';
        });
        return;
      }

      // Membro 100% correspondente encontrado: projetar diretamente no card da Steam
      final isAlreadyInDraft = _isMemberAlreadyInDraft(exactMatch);
      final hasSteam = exactMatch.isSteamLinked;
      final hasRoles = exactMatch.roles.isNotEmpty ||
          (exactMatch.preferredRole != null &&
              exactMatch.preferredRole!.trim().isNotEmpty);

      SteamPreviewDto preview;
      String headerLabel;
      String? error;

      if (isAlreadyInDraft) {
        // Se estiver já no draft, surge diretamente no card com indicador visual e bloqueio
        preview = _createSteamPreview(exactMatch, isAlreadyInUse: true);
        headerLabel = 'JÁ NO DRAFT';
        error = 'Este jogador já está participando desta sessão de draft.';
      } else if (!hasSteam) {
        preview = _createSteamPreview(exactMatch, isAlreadyInUse: false);
        headerLabel = 'SEM VÍNCULO STEAM';
        error = 'Membro não possui conta Steam vinculada ao perfil.';
      } else if (!hasRoles) {
        preview = _createSteamPreview(exactMatch, isAlreadyInUse: false);
        headerLabel = 'SEM FUNÇÕES DOTA 2';
        error = 'Membro não configurou funções (Roles) no Dota 2.';
      } else {
        preview = _createSteamPreview(exactMatch, isAlreadyInUse: false);
        headerLabel = 'DADOS VERIFICADOS';
        error = null;
      }

      setState(() {
        _isSearching = false;
        _selectedMember = exactMatch;
        _steamPreview = preview;
        _customHeaderLabel = headerLabel;
        _errorMessage = error;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _selectedMember = null;
        _steamPreview = null;
        _customHeaderLabel = null;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _selectedMember = null;
        _steamPreview = null;
        _customHeaderLabel = null;
        _errorMessage = 'Falha ao buscar membro. Tente novamente.';
      });
    }
  }

  void _onClearPreview() {
    _searchController.clear();
    setState(() {
      _selectedMember = null;
      _steamPreview = null;
      _errorMessage = null;
      _customHeaderLabel = null;
    });
  }

  Future<void> _handleSubmit() async {
    final member = _selectedMember;
    if (member == null) return;

    if (_isMemberAlreadyInDraft(member)) {
      setState(() {
        _errorMessage = 'Este jogador já está participando desta sessão de draft.';
        _customHeaderLabel = 'JÁ NO DRAFT';
      });
      return;
    }

    if (!member.isSteamLinked) {
      setState(() {
        _errorMessage = 'Membro não possui conta Steam vinculada.';
        _customHeaderLabel = 'SEM VÍNCULO STEAM';
      });
      return;
    }

    final hasRoles = member.roles.isNotEmpty ||
        (member.preferredRole != null && member.preferredRole!.trim().isNotEmpty);
    if (!hasRoles) {
      setState(() {
        _errorMessage = 'Membro não configurou funções (Roles) no Dota 2.';
        _customHeaderLabel = 'SEM FUNÇÕES DOTA 2';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final effectiveRoles =
        member.roles.isNotEmpty ? member.roles : const ['Safe Lane'];
    final preferredRole = member.preferredRole ?? effectiveRoles.first;

    final error = await widget.onAdd(
      name: member.effectiveNickname,
      playerId: member.userId,
      roles: effectiveRoles,
      preferredRole: preferredRole,
      rankTier: member.rankTier,
      avatarUrl: member.avatarUrl,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEligible = _selectedMember != null &&
        !_isMemberAlreadyInDraft(_selectedMember!) &&
        _selectedMember!.isSteamLinked &&
        (_selectedMember!.roles.isNotEmpty ||
            (_selectedMember!.preferredRole != null &&
                _selectedMember!.preferredRole!.trim().isNotEmpty));

    final bool canSubmit = isEligible && !_isSubmitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Pesquise um membro da comunidade pelo Nick completo ou link da Steam. O jogador precisa ter conta Steam vinculada e funções definidas para ser adicionado ao draft.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // 1. Linha de Busca Canônica (46px) com Botão [BUSCAR] Integrado
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppInput(
                controller: _searchController,
                labelText: 'Nick exato ou link Steam',
                hintText: 'Digite o nick completo com mesmos caracteres...',
                prefixIcon: Icons.search_rounded,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: AppColors.textSecondary,
                        onPressed: _onClearPreview,
                      )
                    : null,
                onChanged: _onSearchChanged,
                onFieldSubmitted: (_) => _handleManualSearch(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 46,
              child: AppButton(
                text: 'BUSCAR',
                icon: Icons.search_rounded,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.primary,
                isLoading: _isSearching,
                onPressed: _handleManualSearch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 2. Card Oficial de Pré-Visualização da Steam do Shared
        // Projetado diretamente com os dados do membro encontrado
        SteamPreviewCard(
          preview: _steamPreview,
          isVerifying: _isSearching,
          errorText: _errorMessage,
          customHeaderLabel: _customHeaderLabel,
          onClear: _onClearPreview,
          currentIdentifier: _searchController.text.trim(),
        ),

        const SizedBox(height: 20),

        // 3. Rodapé de Ações
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              text: 'CANCELAR',
              size: AppButtonSize.small,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop(false),
            ),
            const SizedBox(width: 8),
            AppButton(
              text: 'ADICIONAR À POOL',
              icon: Icons.person_add_rounded,
              size: AppButtonSize.small,
              variant: AppButtonVariant.primary,
              isLoading: _isSubmitting,
              onPressed: canSubmit ? _handleSubmit : null,
            ),
          ],
        ),
      ],
    );
  }
}

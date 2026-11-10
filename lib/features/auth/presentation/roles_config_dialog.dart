import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../models/dota_role_def.dart';
import '../models/login_response.dart';
import 'widgets/role_selection_tile.dart';

/// Modal padronizado para visualização e edição de Funções e Função Principal do jogador no Dota 2.
/// - Carrega as seleções já salvas da sessão e do endpoint GET /api/v1/auth/me
/// - Detecta alterações não salvas (_hasChanges)
/// - Se o usuário tentar fechar com alterações pendentes, solicita confirmação via AppConfirmDialog
/// - Integra com PUT /api/v1/auth/roles e atualiza a sessão segura em memória
class RolesConfigDialog extends StatefulWidget {
  final LoginResponse? currentProfile;

  const RolesConfigDialog({
    super.key,
    this.currentProfile,
  });

  /// Exibe o modal centralizado respeitando o design system dark e BoxConstraints(maxWidth: 440).
  static Future<bool?> show(
    BuildContext context, {
    LoginResponse? currentProfile,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => RolesConfigDialog(currentProfile: currentProfile),
    );
  }

  @override
  State<RolesConfigDialog> createState() => _RolesConfigDialogState();
}

class _RolesConfigDialogState extends State<RolesConfigDialog> {
  late Set<int> _selectedRoleIds;
  int? _preferredRoleId;

  // Snapshot do estado inicial para detecção precisa de alterações
  late Set<int> _initialRoleIds;
  int? _initialPreferredRoleId;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initFromProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestRolesFromBackend();
    });
  }

  void _initFromProfile() {
    final profile = widget.currentProfile;
    _selectedRoleIds = <int>{};

    if (profile != null) {
      for (final rName in profile.roles) {
        final def = DotaRoleDef.availableRoles.firstWhere(
          (d) => d.name.toLowerCase() == rName.toLowerCase(),
          orElse: () => DotaRoleDef.availableRoles.firstWhere(
            (d) => d.id.toString() == rName,
            orElse: () => DotaRoleDef.availableRoles.first,
          ),
        );
        _selectedRoleIds.add(def.id);
      }

      if (profile.preferredRole != null) {
        final prefName = profile.preferredRole!.toLowerCase();
        for (final def in DotaRoleDef.availableRoles) {
          if (def.name.toLowerCase() == prefName ||
              def.id.toString() == prefName ||
              def.roleName.toLowerCase() == prefName ||
              def.posLabel.toLowerCase() == prefName) {
            _preferredRoleId = def.id;
            break;
          }
        }
      }
    }

    if (_preferredRoleId != null &&
        !_selectedRoleIds.contains(_preferredRoleId)) {
      _selectedRoleIds.add(_preferredRoleId!);
    }

    // Salva o snapshot inicial
    _initialRoleIds = Set<int>.from(_selectedRoleIds);
    _initialPreferredRoleId = _preferredRoleId;
  }

  /// Busca o estado mais recente do perfil diretamente da API (GET /api/v1/auth/me)
  Future<void> _fetchLatestRolesFromBackend() async {
    try {
      final data = await ApiClient.get(ApiEndpoints.authMe, requiresAuth: true);
      if (!mounted) return;

      final rolesList = data['roles'] as List<dynamic>?;
      final pref = data['preferredRole']?.toString();

      if (rolesList != null) {
        final loadedIds = <int>{};
        for (final rName in rolesList) {
          final def = DotaRoleDef.availableRoles.firstWhere(
            (d) => d.name.toLowerCase() == rName.toString().toLowerCase(),
            orElse: () => DotaRoleDef.availableRoles.firstWhere(
              (d) => d.id.toString() == rName.toString(),
              orElse: () => DotaRoleDef.availableRoles.first,
            ),
          );
          loadedIds.add(def.id);
        }

        int? loadedPrefId;
        if (pref != null) {
          final prefNorm = pref.toLowerCase();
          for (final def in DotaRoleDef.availableRoles) {
            if (def.name.toLowerCase() == prefNorm ||
                def.id.toString() == prefNorm ||
                def.roleName.toLowerCase() == prefNorm ||
                def.posLabel.toLowerCase() == prefNorm) {
              loadedPrefId = def.id;
              break;
            }
          }
        }

        setState(() {
          _selectedRoleIds = loadedIds;
          _preferredRoleId = loadedPrefId;
          _initialRoleIds = Set<int>.from(loadedIds);
          _initialPreferredRoleId = loadedPrefId;
        });
      }
    } catch (_) {
      // Caso a API esteja inacessível, mantém o snapshot dos dados locais em memória
    }
  }

  /// Verifica se o usuário alterou qualquer função ou a preferida em relação ao original
  bool get _hasChanges {
    if (_initialRoleIds.length != _selectedRoleIds.length) return true;
    if (!_initialRoleIds.containsAll(_selectedRoleIds)) return true;
    if (_initialPreferredRoleId != _preferredRoleId) return true;
    return false;
  }

  /// Interceptador de fechamento seguro com confirmação de descarte de alterações
  Future<void> _handleCloseRequest() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(false);
      return;
    }

    final shouldDiscard = await AppConfirmDialog.show(
      context,
      title: 'DESCARTAR ALTERAÇÕES?',
      message:
          'Você possui alterações não salvas nas suas funções. Deseja realmente sair e descartá-las?',
      confirmLabel: 'DESCARTAR',
      cancelLabel: 'CONTINUAR EDITANDO',
      isDestructive: true,
    );

    if (shouldDiscard && mounted) {
      Navigator.of(context).pop(false);
    }
  }

  void _toggleRole(DotaRoleDef def) {
    setState(() {
      if (_selectedRoleIds.contains(def.id)) {
        _selectedRoleIds.remove(def.id);
        if (_preferredRoleId == def.id) {
          _preferredRoleId =
              _selectedRoleIds.isNotEmpty ? _selectedRoleIds.first : null;
        }
      } else {
        _selectedRoleIds.add(def.id);
        _preferredRoleId ??= def.id;
      }
    });
  }

  void _setPreferredRole(int id) {
    setState(() {
      _selectedRoleIds.add(id);
      _preferredRoleId = id;
    });
  }

  Future<void> _handleSave() async {
    if (_selectedRoleIds.isEmpty) {
      AppFeedback.showWarning(
        context,
        message: 'Selecione ao menos uma função em que você joga.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final roleIdsList = _selectedRoleIds.toList()..sort();
      final body = <String, dynamic>{
        'roles': roleIdsList,
        'preferredRole': _preferredRoleId ?? roleIdsList.first,
      };

      final response = await ApiClient.put(
        ApiEndpoints.authUpdateRoles,
        body: body,
        requiresAuth: true,
      );

      final returnedRoles = response['roles'] as List<dynamic>?;
      final roleNames = returnedRoles != null
          ? returnedRoles.map((e) => e.toString()).toList()
          : DotaRoleDef.availableRoles
              .where((d) => _selectedRoleIds.contains(d.id))
              .map((d) => d.name)
              .toList();

      final returnedPref = response['preferredRole']?.toString();
      final prefName = returnedPref ??
          DotaRoleDef.availableRoles
              .firstWhere(
                (d) => d.id == _preferredRoleId,
                orElse: () => DotaRoleDef.availableRoles.first,
              )
              .name;

      // Atualiza a sessão em memória
      await TokenStorage.updateSessionProfile({
        'roles': roleNames,
        'preferredRole': prefName,
      });

      // Atualiza o snapshot para que fechar não pergunte de descarte
      _initialRoleIds = Set<int>.from(_selectedRoleIds);
      _initialPreferredRoleId = _preferredRoleId;

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          message: 'Funções do Dota 2 salvas com sucesso!',
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppFeedback.showError(context, message: e.message);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          message: 'Falha ao salvar funções. Verifique sua conexão.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleCloseRequest();
      },
      child: AppDialog(
        icon: Icons.sports_esports_rounded,
        iconColor: AppColors.primaryNeon,
        title: 'FUNÇÕES NO DOTA 2',
        maxWidth: 440,
        onClose: _handleCloseRequest,
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Caixa de Informação Estruturada
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.primaryNeon,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Marque as posições que você joga no Dota 2. Clique na estrela ⭐ para definir sua função favorita.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Card de Funções com Cabeçalho Próprio
              Container(
                decoration: BoxDecoration(
                  color: AppColors.navSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.canvasSurface,
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.7),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 14,
                            color: AppColors.primaryNeon,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'ESCOLHA SUAS FUNÇÕES',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: DotaRoleDef.availableRoles.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.border.withValues(alpha: 0.5),
                        height: 1,
                        thickness: 1,
                      ),
                      itemBuilder: (context, index) {
                        final def = DotaRoleDef.availableRoles[index];
                        return RoleSelectionTile(
                          def: def,
                          isSelected: _selectedRoleIds.contains(def.id),
                          isPreferred: _preferredRoleId == def.id,
                          onToggle: () => _toggleRole(def),
                          onSetPreferred: () => _setPreferredRole(def.id),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          AppCancelButton(
            height: 44,
            label: 'CANCELAR',
            onPressed: _handleCloseRequest,
          ),
          AppConfirmButton(
            height: 44,
            label: 'SALVAR FUNÇÕES',
            isLoading: _isSaving,
            backgroundColor: AppColors.primaryNeon,
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
    );
  }
}

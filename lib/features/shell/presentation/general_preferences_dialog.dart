import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../../auth/models/login_response.dart';

/// Modal de Preferências Gerais exclusivo para administradores (SuperAdmin / TournamentAdmin).
/// Permite configurar a Página Inicial Preferencial (Modo Jogador vs Painel Admin)
/// com persistência no backend (GET / PUT /api/v1/admin/preferences).
class GeneralPreferencesDialog extends StatefulWidget {
  final LoginResponse? currentProfile;

  const GeneralPreferencesDialog({
    super.key,
    this.currentProfile,
  });

  /// Exibe o diálogo com restrição de 440px e animação suave
  static Future<void> show(BuildContext context, {LoginResponse? currentProfile}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) => GeneralPreferencesDialog(
        currentProfile: currentProfile,
      ),
    );
  }

  @override
  State<GeneralPreferencesDialog> createState() => _GeneralPreferencesDialogState();
}

class _GeneralPreferencesDialogState extends State<GeneralPreferencesDialog> {
  late String _selectedMode;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentProfile?.preferredLandingPage;
    _selectedMode = (initial?.toLowerCase() == 'admin') ? 'Admin' : 'Player';
    _fetchPreferences();
  }

  Future<void> _fetchPreferences() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get(
        ApiEndpoints.adminPreferences,
        requiresAuth: true,
      );

      final rawData = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;

      final landing = rawData['preferredLandingPage']?.toString() ??
          rawData['PreferredLandingPage']?.toString();

      if (landing != null && mounted) {
        setState(() {
          _selectedMode = (landing.toLowerCase() == 'admin') ? 'Admin' : 'Player';
        });
      }
    } catch (_) {
      // Caso a rota esteja offline, mantém o valor do perfil em sessão
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await ApiClient.put(
        ApiEndpoints.adminPreferences,
        body: {'preferredLandingPage': _selectedMode},
        requiresAuth: true,
      );

      // Atualiza o perfil na sessão segura em memória
      await TokenStorage.updateSessionProfile({
        'preferredLandingPage': _selectedMode,
      });

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          message: 'Preferência atualizada com sucesso!',
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        AppFeedback.showError(context, message: e.message);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.showError(
          context,
          message: 'Falha ao salvar preferências no servidor.',
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
    return AppDialog(
      icon: Icons.tune_rounded,
      iconColor: AppColors.primaryNeon,
      title: 'PREFERÊNCIAS GERAIS',
      maxWidth: 440,
      onClose: () => Navigator.of(context).pop(),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Caixa de Informação Estruturada (Callout)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      'Defina qual tela principal deve ser carregada por padrão ao realizar login na plataforma.',
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

            // 2. Card Estruturado de Seleção
            Container(
              decoration: BoxDecoration(
                color: AppColors.canvasSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.8),
                  width: 1.0,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Faixa Superior Interna do Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight.withValues(alpha: 0.65),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.border.withValues(alpha: 0.6),
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.dashboard_customize_rounded,
                          size: 13,
                          color: AppColors.primaryNeon,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PÁGINA INICIAL PREFERENCIAL',
                          style: AppText.caption.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Área dos cards de seleção
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: AppColors.dotaGold,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              // Opção 1: Modo Jogador
                              Expanded(
                                child: AppSelectCard(
                                  title: 'Modo Jogador',
                                  subtitle: 'Dashboard de Jogador',
                                  icon: Icons.sports_esports_rounded,
                                  accentColor: AppColors.primaryNeon,
                                  isSelected: _selectedMode == 'Player',
                                  onTap: () {
                                    setState(() => _selectedMode = 'Player');
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Opção 2: Painel Administrador
                              Expanded(
                                child: AppSelectCard(
                                  title: 'Painel Admin',
                                  subtitle: 'Gestão e Moderação',
                                  icon: Icons.admin_panel_settings_rounded,
                                  accentColor: AppColors.dotaGold,
                                  isSelected: _selectedMode == 'Admin',
                                  onTap: () {
                                    setState(() => _selectedMode = 'Admin');
                                  },
                                ),
                              ),
                            ],
                          ),
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppConfirmButton(
          height: 44,
          label: 'SALVAR ALTERAÇÕES',
          isLoading: _isSaving,
          backgroundColor: AppColors.primaryNeon,
          onPressed: _isLoading ? null : _savePreferences,
        ),
      ],
    );
  }
}

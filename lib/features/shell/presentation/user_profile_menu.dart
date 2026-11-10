import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../../auth/models/login_response.dart';
import '../../auth/presentation/roles_config_dialog.dart';
import '../../auth/presentation/steam_config_dialog.dart';
import 'general_preferences_dialog.dart';
import 'system_security_dialog.dart';

/// Menu Suspenso de Perfil do Usuário (UserProfileMenu).
/// Exibido na barra superior (TopBar) no extremo direito:
/// - Caixa clicável moderna com borda e fundo estilizado.
/// - Avatar com foto oficial da Steam ou Logo Tsurus como placeholder (sem texto MA genérico).
/// - Integração reativa com TokenStorage.profileNotifier para atualização instantânea da Steam.
/// - Opções de Configurar Steam, Preferências Gerais (Admin) e Logout seguro.
class UserProfileMenu extends StatefulWidget {
  const UserProfileMenu({super.key});

  /// Fluxo unificado e seguro de confirmação e encerramento de sessão (DRY).
  static Future<void> confirmAndLogout(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'ENCERRAR SESSÃO',
      message: 'Deseja realmente sair da sua conta?',
      confirmLabel: 'SAIR',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirm && context.mounted) {
      await TokenStorage.clear();
      if (context.mounted) {
        AppFeedback.showInfo(context, message: 'Sessão encerrada com sucesso.');
        context.go('/login');
      }
    }
  }

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  @override
  void initState() {
    super.initState();
    TokenStorage.getUserProfile(); // Assegura inicialização do cache/notifier
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return ValueListenableBuilder<LoginResponse?>(
      valueListenable: TokenStorage.profileNotifier,
      builder: (context, profile, _) {
        final name = profile?.displayName ?? 'Usuário';
        final isSteamLinked = profile?.isSteamLinked == true;
        final canManage = profile?.canManageTournaments == true;

        return PopupMenuButton<String>(
          tooltip: 'Menu do Usuário',
          offset: const Offset(0, 48),
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              UserProfileMenu.confirmAndLogout(context);
            } else if (value == 'steam') {
              SteamConfigDialog.show(
                context,
                isMandatory: false,
                currentProfile: profile,
              );
            } else if (value == 'roles') {
              RolesConfigDialog.show(
                context,
                currentProfile: profile,
              );
            } else if (value == 'preferences') {
              GeneralPreferencesDialog.show(
                context,
                currentProfile: profile,
              );
            } else if (value == 'security') {
              SystemSecurityDialog.show(context);
            }
          },
          itemBuilder: (context) => [
            // 1. Cabeçalho com Dados do Usuário (limpo, sem badge SUPERADMIN nem jogo ativo)
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      AppAvatar.steamOrBrand(
                        avatarUrl: profile?.dotaAvatarUrl,
                        size: 36,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (profile?.email != null) ...[
                              Text(
                                profile!.email,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 18),
                ],
              ),
            ),

            // 2. Opção Oficial de Configurar Steam
            PopupMenuItem(
              value: 'steam',
              child: Row(
                children: [
                  const Icon(
                    Icons.sports_esports_rounded,
                    size: 18,
                    color: AppColors.primaryNeon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isSteamLinked ? 'Configurar Steam' : 'Vincular Conta Steam',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isSteamLinked)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: AppColors.primaryNeon,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primaryNeon.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Text(
                        'PENDENTE',
                        style: TextStyle(
                          color: AppColors.primaryNeon,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 3. Opção Oficial de Funções / Roles no Dota 2 (para quem tem Steam ou já configurou)
            if (isSteamLinked || (profile?.roles.isNotEmpty == true))
              PopupMenuItem(
                value: 'roles',
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: AppColors.dotaGold,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Funções no Dota',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (profile?.preferredRole != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.dotaGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.dotaGold.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          profile!.preferredRole!.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.dotaGold,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // 4. Opção de Preferências Gerais (visível apenas para SuperAdmin e TournamentAdmin)
            if (canManage)
              const PopupMenuItem(
                value: 'preferences',
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.dotaGold,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Preferências Gerais',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Opção de Segurança do Sistema (exclusivo para SuperAdmin)
            if (profile?.isSuperAdmin == true)
              const PopupMenuItem(
                value: 'security',
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 18,
                      color: AppColors.primaryNeon,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Segurança do Sistema',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const PopupMenuDivider(height: 8),

            // 4. Opção de Sair da Conta (Logout Seguro)
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: AppColors.feedbackError,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Sair da Conta',
                    style: TextStyle(
                      color: AppColors.feedbackError,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Caixa de Ação Clicável de Destaque
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.border,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppAvatar.steamOrBrand(
                  avatarUrl: profile?.dotaAvatarUrl,
                  size: 26,
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 130,
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

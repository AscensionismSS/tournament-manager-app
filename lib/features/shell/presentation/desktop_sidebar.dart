import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/app_mode.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../../auth/models/login_response.dart';
import 'user_profile_menu.dart';

/// Item de menu para a barra lateral
class SidebarNavItem {
  final String label;
  final IconData icon;
  final String routePath;

  const SidebarNavItem({
    required this.label,
    required this.icon,
    required this.routePath,
  });
}

/// Menu Lateral (Sidebar Oficial Tsurus Plus+).
/// Renderiza a navegação da plataforma com suporte a alternância dinâmica
/// entre Modo Jogador e Painel Admin para administradores autorizados.
class DesktopSidebar extends StatelessWidget {
  final String currentRoute;
  final VoidCallback? onNavigate;

  const DesktopSidebar({
    super.key,
    this.currentRoute = '/',
    this.onNavigate,
  });

  /// Itens de navegação do Modo Jogador
  static const List<SidebarNavItem> playerNavItems = [
    SidebarNavItem(
      label: 'Início',
      icon: Icons.sports_esports_rounded,
      routePath: '/',
    ),
    SidebarNavItem(
      label: 'Torneios',
      icon: Icons.emoji_events_rounded,
      routePath: '/tournaments',
    ),
    SidebarNavItem(
      label: 'Membros',
      icon: Icons.groups_rounded,
      routePath: '/members',
    ),
  ];

  /// Itens de navegação do Painel Admin (Inicia direto em Convites de Acesso)
  static const List<SidebarNavItem> adminNavItems = [
    SidebarNavItem(
      label: 'Convites de Acesso',
      icon: Icons.mark_email_read_rounded,
      routePath: '/admin/invites',
    ),
    SidebarNavItem(
      label: 'Gestão de Membros',
      icon: Icons.manage_accounts_rounded,
      routePath: '/admin/members',
    ),
    SidebarNavItem(
      label: 'Criador de Torneios',
      icon: Icons.add_circle_outline_rounded,
      routePath: '/admin/tournaments',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LoginResponse?>(
      valueListenable: TokenStorage.profileNotifier,
      builder: (context, profile, _) {
        final canManage = profile?.canManageTournaments ?? false;

        return ValueListenableBuilder<AppMode>(
          valueListenable: AppModeState.currentMode,
          builder: (context, activeMode, _) {
            final activeItems = (canManage && activeMode == AppMode.admin)
                ? adminNavItems
                : playerNavItems;

            return Container(
              width: 270,
              decoration: BoxDecoration(
                color: AppColors.navSurface,
                border: Border(
                  right: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.8),
                    width: 1.0,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Cabeçalho da Sidebar com Logo e Marca Oficial
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryNeon.withValues(alpha: 0.7),
                              width: 1.2,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/company_logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.sports_esports_rounded,
                                size: 16,
                                color: AppColors.primaryNeon,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TsurusBrandTitle(
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                            Text(
                              'ARENA COMPETITIVA',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. Seletor de Modo Segmentado (Visível exclusivamente para administradores)
                  if (canManage) ...[
                    _buildModeSwitcher(context, activeMode),
                    const SizedBox(height: 6),
                    const Divider(color: AppColors.border, height: 1),
                  ],

                  // 3. Lista de Itens de Navegação do Modo Ativo
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      children: activeItems.map((item) {
                        final isSelected = currentRoute == item.routePath ||
                            (item.routePath != '/' &&
                                currentRoute.startsWith(item.routePath));

                        return _buildNavItem(context, item, isSelected);
                      }).toList(),
                    ),
                  ),

                  const Divider(color: AppColors.border, height: 1),

                  // 4. Rodapé com Perfil do Usuário e Logout (Reativo via profileNotifier)
                  _buildFooter(context, profile),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Seletor de Modo Segmentado (Modo Jogador vs Painel Admin)
  Widget _buildModeSwitcher(BuildContext context, AppMode currentMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Aba 1: Modo Jogador
          Expanded(
            child: _buildSwitcherTab(
              context: context,
              label: 'Jogador',
              icon: Icons.sports_esports_rounded,
              isSelected: currentMode == AppMode.player,
              accentColor: AppColors.primaryNeon,
              onTap: () {
                if (currentMode != AppMode.player) {
                  AppModeState.setMode(AppMode.player);
                  if (currentRoute.startsWith('/admin/tournaments')) {
                    context.go('/tournaments');
                  } else if (currentRoute.startsWith('/admin/members')) {
                    context.go('/members');
                  } else {
                    context.go('/tournaments');
                  }
                }
              },
            ),
          ),
          const SizedBox(width: 3),
          // Aba 2: Painel Admin
          Expanded(
            child: _buildSwitcherTab(
              context: context,
              label: 'Admin',
              icon: Icons.admin_panel_settings_rounded,
              isSelected: currentMode == AppMode.admin,
              accentColor: AppColors.dotaGold,
              onTap: () {
                if (currentMode != AppMode.admin) {
                  AppModeState.setMode(AppMode.admin);
                  if (currentRoute.startsWith('/tournaments')) {
                    context.go('/admin/tournaments');
                  } else if (currentRoute.startsWith('/members') || currentRoute.startsWith('/teams')) {
                    context.go('/admin/members');
                  } else {
                    context.go('/admin/invites');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherTab({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.7)
                : Colors.transparent,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? accentColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, SidebarNavItem item, bool isSelected) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryNeon.withValues(alpha: 0.65)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            item.icon,
            size: 20,
            color: isSelected ? AppColors.primaryNeon : AppColors.textSecondary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onNavigate?.call();
          if (currentRoute != item.routePath) {
            context.go(item.routePath);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: content,
      ),
    );
  }

  Widget _buildFooter(BuildContext context, LoginResponse? profile) {
    final name = profile?.displayName ?? 'Admin';
    final role = profile?.role ?? 'User';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      child: Row(
        children: [
          AppAvatar.steamOrBrand(
            avatarUrl: profile?.dotaAvatarUrl,
            size: 32,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  role.toUpperCase(),
                  style: TextStyle(
                    color: profile?.isSuperAdmin == true
                        ? AppColors.dotaGold
                        : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.logout_rounded,
            size: AppIconButtonSize.small,
            variant: AppIconButtonVariant.ghost,
            tooltip: 'Sair da Conta',
            onPressed: () => UserProfileMenu.confirmAndLogout(context),
          ),
        ],
      ),
    );
  }
}

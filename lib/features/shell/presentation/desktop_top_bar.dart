import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import 'notification_bell_menu.dart';
import 'user_profile_menu.dart';

/// Barra Superior Oficial da Plataforma (NavBar / TopBar).
/// Responsável por:
/// - Ocupar a linha reta horizontal toda (largura 100%).
/// - Botão de toggle da barra lateral (expandir/recolher abaixo da barra).
/// - Logo da empresa fixo e marca TSURUS PLUS+.
/// - Menu isolado de perfil do usuário ([UserProfileMenu]).
class DesktopTopBar extends StatelessWidget {
  final bool isSidebarOpen;
  final VoidCallback onToggleSidebar;
  final String title;

  const DesktopTopBar({
    super.key,
    required this.isSidebarOpen,
    required this.onToggleSidebar,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 720;

    return Container(
      height: 64,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 16 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.navSurface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Grupo Esquerdo (ocupa todo o espaço restante e empurra o perfil para a direita máxima)
          Expanded(
            child: Row(
              children: [
                // 1.1 Botão Hambúrguer no Extremo Esquerdo Máximo
                AppIconButton(
                  icon: isSidebarOpen ? Icons.menu_open_rounded : Icons.menu_rounded,
                  size: AppIconButtonSize.medium,
                  variant: isSidebarOpen
                      ? AppIconButtonVariant.primary
                      : AppIconButtonVariant.ghost,
                  tooltip: isSidebarOpen ? 'Recolher Menu Lateral' : 'Expandir Menu Lateral',
                  onPressed: onToggleSidebar,
                ),
                const SizedBox(width: 4),

                // 1.2 Logo Fixo da Empresa (Símbolo Oficial)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryNeon.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNeon.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/company_logo.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.sports_esports_rounded,
                        size: 20,
                        color: AppColors.primaryNeon,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // 1.3 Em telas largas: Nome da Plataforma TSURUS PLUS+
                if (isWide) ...[
                  const TsurusBrandTitle(
                    fontSize: 16.5,
                    letterSpacing: 1.1,
                  ),
                  const SizedBox(width: 12),
                ],

                // 1.4 Divisor Vertical (SEMPRE presente entre Logo/Marca e o Título da Página)
                Container(
                  height: 18,
                  width: 1.2,
                  color: AppColors.borderHighlight,
                ),
                const SizedBox(width: 10),

                // 1.5 Nome da Página Aberta (sem cortes desnecessários, com espaço livre)
                Flexible(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Oswald',
                      fontSize: isWide ? 13.5 : 13.0,
                      fontWeight: isWide ? FontWeight.w600 : FontWeight.w700,
                      color: isWide ? AppColors.textSecondary : Colors.white,
                      letterSpacing: isWide ? 0.7 : 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 2. Sininho Global de Notificações SSE em Tempo Real
          const NotificationBellMenu(),
          const SizedBox(width: 10),

          // 3. Menu Isolado de Perfil do Usuário ancorado no Extremo Direito Máximo
          const UserProfileMenu(),
        ],
      ),
    );
  }
}

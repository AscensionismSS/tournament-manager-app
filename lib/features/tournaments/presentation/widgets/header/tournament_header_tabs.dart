import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../../controllers/tournament_details_controller.dart';
import '../tournament_nav_tab_item.dart';

/// Barra de Abas de Navegação Independente do Campeonato (SRP & Responsive).
/// - No Mobile (< 680px): Dropdown `AppSelectBox` ocupando a largura total (46px).
/// - No Desktop (>= 680px): Barra horizontal com indicador inferior e micro-hover.
class TournamentHeaderTabs extends StatelessWidget {
  final TournamentDetailsController controller;
  final bool canManage;
  final ValueChanged<TournamentDetailTab> onSelectTab;

  const TournamentHeaderTabs({
    super.key,
    required this.controller,
    required this.canManage,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = controller.visibleTabsFor(canManage: canManage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 680;

        if (isCompact) {
          // Versão Mobile / Tela Pequena: SelectBox moderno em largura total
          return AppSelectBox<TournamentDetailTab>(
            value: controller.activeTab,
            isHighlighted: true,
            prefixIcon: Icons.tab_rounded,
            options: tabs
                .map(
                  (tab) => AppSelectOption<TournamentDetailTab>(
                    value: tab,
                    label: tab.label.toUpperCase(),
                    icon: tab.icon,
                  ),
                )
                .toList(),
            onChanged: (tab) {
              if (tab != null) onSelectTab(tab);
            },
            height: 46,
            width: double.infinity,
            accentColor: AppColors.primaryNeon,
            showSelectedIcon: true,
          );
        }

        // Versão Desktop: Barra Horizontal Transparente Moderna com Pills destacados
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.85),
                width: 1.0,
              ),
            ),
          ),
          child: Focus(
            canRequestFocus: false,
            descendantsAreFocusable: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    TournamentNavTabItem(
                      tab: tabs[i],
                      isSelected: controller.activeTab == tabs[i],
                      onTap: () => onSelectTab(tabs[i]),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

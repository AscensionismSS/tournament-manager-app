import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

/// Barra de progresso das 4 etapas oficiais do Draft (SRP & Dumb UI).
/// Adapta-se fluidamente entre Desktop (barra completa com conectores)
/// e Mobile (pills compactos com rolagem horizontal).
class DraftHeaderStepper extends StatelessWidget {
  final int currentStep; // 1: Capitães, 2: Ordem, 3: Titulares, 4: Reservas
  final String stateLabel;
  final Widget? action;

  const DraftHeaderStepper({
    super.key,
    required this.currentStep,
    required this.stateLabel,
    this.action,
  });

  static const List<_StepInfo> _steps = [
    _StepInfo(step: 1, title: 'Capitães', icon: Icons.military_tech_rounded),
    _StepInfo(step: 2, title: 'Ordem do Draft', icon: Icons.format_list_numbered_rounded),
    _StepInfo(step: 3, title: 'Titulares (Snake)', icon: Icons.sports_esports_rounded),
    _StepInfo(step: 4, title: 'Reservas & Conclusão', icon: Icons.group_add_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < _steps.length; i++) ...[
                        _buildStepPill(_steps[i]),
                        if (i < _steps.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action!,
                ],
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (int i = 0; i < _steps.length; i++) ...[
                      Expanded(child: _buildStepItem(_steps[i])),
                      if (i < _steps.length - 1)
                        _buildConnector(isCompleted: currentStep > _steps[i].step),
                    ],
                  ],
                ),
              ),
              if (action != null) ...[
                const SizedBox(width: 14),
                Container(
                  height: 28,
                  width: 1.0,
                  color: AppColors.border.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 14),
                action!,
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepItem(_StepInfo info) {
    final bool isCompleted = currentStep > info.step;
    final bool isActive = currentStep == info.step;

    final Color primaryColor = isActive
        ? AppColors.dotaGold
        : (isCompleted ? AppColors.dotaGoldLight : AppColors.textSecondary.withValues(alpha: 0.5));

    final Color badgeBg = isActive
        ? AppColors.dotaGold.withValues(alpha: 0.20)
        : (isCompleted
            ? AppColors.dotaGold.withValues(alpha: 0.12)
            : AppColors.canvasSurface.withValues(alpha: 0.6));

    final Color borderColor = isActive
        ? AppColors.dotaGoldLight
        : (isCompleted ? AppColors.dotaGold.withValues(alpha: 0.5) : AppColors.border);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: badgeBg,
            border: Border.all(color: borderColor, width: isActive ? 1.5 : 1.0),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.dotaGold.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check_rounded, size: 16, color: AppColors.dotaGoldLight)
                : Text(
                    '${info.step}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ETAPA ${info.step}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: isActive ? AppColors.dotaGold : AppColors.textSecondary.withValues(alpha: 0.65),
                ),
              ),
              Text(
                info.title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                  letterSpacing: 0.4,
                  color: isActive ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepPill(_StepInfo info) {
    final bool isCompleted = currentStep > info.step;
    final bool isActive = currentStep == info.step;

    final Color borderColor = isActive
        ? AppColors.dotaGoldLight
        : (isCompleted ? AppColors.dotaGold.withValues(alpha: 0.5) : AppColors.border);

    final Color bgColor = isActive
        ? AppColors.dotaGold.withValues(alpha: 0.16)
        : (isCompleted ? AppColors.dotaGold.withValues(alpha: 0.08) : Colors.transparent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCompleted ? Icons.check_circle_rounded : info.icon,
            size: 14,
            color: isActive || isCompleted ? AppColors.dotaGoldLight : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            info.title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isCompleted}) {
    return Container(
      width: 24,
      height: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isCompleted ? AppColors.dotaGold.withValues(alpha: 0.6) : AppColors.border,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _StepInfo {
  final int step;
  final String title;
  final IconData icon;

  const _StepInfo({
    required this.step,
    required this.title,
    required this.icon,
  });
}


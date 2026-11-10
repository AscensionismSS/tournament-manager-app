import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';

/// Diálogo informativo para explicar detalhadamente as 5 funções (roles) oficiais do Dota 2 (SRP & Dumb UI).
class DotaRolesGuideDialog extends StatelessWidget {
  const DotaRolesGuideDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AppDialog(
        title: 'FUNÇÕES DO DOTA 2',
        icon: Icons.info_outline_rounded,
        iconColor: AppColors.dotaGold,
        maxWidth: 460,
        content: const DotaRolesGuideDialog(),
        actions: [
          AppButton(
            text: 'ENTENDI',
            icon: Icons.check_rounded,
            size: AppButtonSize.small,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  static const List<_RoleGuideInfo> _roles = [
    _RoleGuideInfo(
      role: DotaRoleType.safeLane,
      posNumber: 'Posição 1',
      title: 'Safe Lane (Hard Carry)',
      description:
          'Carregador principal. Prioridade máxima de farm para acumular itens cruciais e liderar o dano nas lutas do final do jogo.',
    ),
    _RoleGuideInfo(
      role: DotaRoleType.midLane,
      posNumber: 'Posição 2',
      title: 'Mid Lane (Solo Mid)',
      description:
          'Trilha do meio. Ganho rápido de experiência (XP), controle de ritmo da partida, disputa de runas e rotações para criar vantagem.',
    ),
    _RoleGuideInfo(
      role: DotaRoleType.offLane,
      posNumber: 'Posição 3',
      title: 'Offlane (Trilha Difícil)',
      description:
          'Iniciador e linha de frente (tank). Perturba a Safe Lane adversária, cria espaço no mapa e adquire auras utilitárias para o time.',
    ),
    _RoleGuideInfo(
      role: DotaRoleType.support,
      posNumber: 'Posição 4',
      title: 'Soft Support (Suporte Suave)',
      description:
          'Suporte móvel (roaming). Auxilia a Offlane, disputa runas, faz rotações para emboscadas e fornece habilidades utilitárias.',
    ),
    _RoleGuideInfo(
      role: DotaRoleType.hardSupport,
      posNumber: 'Posição 5',
      title: 'Hard Support (Suporte Total)',
      description:
          'Protetor da Safe Lane. Garante visão tática (wards), faz stacks de campos neutros, salva aliados e viabiliza o farm do Carry.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Cada equipe competitiva de Dota 2 é composta por 5 posições com atribuições táticas complementares:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        for (final info in _roles) ...[
          _buildRoleRow(info),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildRoleRow(_RoleGuideInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.canvasSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: info.role.officialColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: info.role.officialColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: info.role.officialColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            child: Center(
              child: DotaRoleIcon(
                role: info.role,
                size: 18,
                color: info.role.officialColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      info.posNumber.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: info.role.officialColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      info.title,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleGuideInfo {
  final DotaRoleType role;
  final String posNumber;
  final String title;
  final String description;

  const _RoleGuideInfo({
    required this.role,
    required this.posNumber,
    required this.title,
    required this.description,
  });
}

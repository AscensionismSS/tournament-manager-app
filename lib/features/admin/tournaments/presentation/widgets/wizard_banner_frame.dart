import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/tournament_wizard_state.dart';

/// Moldura interativa de banner do campeonato com preview cinematográfico em tempo real.
class WizardBannerFrame extends StatelessWidget {
  final TournamentWizardState state;
  final TextEditingController nameController;
  final bool isUploadingBanner;
  final VoidCallback onPickBanner;
  final VoidCallback onRestoreDefault;

  const WizardBannerFrame({
    super.key,
    required this.state,
    required this.nameController,
    required this.isUploadingBanner,
    required this.onPickBanner,
    required this.onRestoreDefault,
  });

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 132.0;
    final bool hasCustomBanner = state.bannerBytes != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCustomBanner
              ? AppColors.primaryNeon.withValues(alpha: 0.55)
              : AppColors.borderHighlight.withValues(alpha: 0.95),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da Moldura
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.panorama_rounded,
                  size: 14,
                  color: AppColors.primaryNeon,
                ),
                const SizedBox(width: 6),
                const Text(
                  'MOLDURA DO BANNER (CAPA DO CAMPEONATO)',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.borderHighlight.withValues(alpha: 0.7),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        size: 10,
                        color: AppColors.dotaGold,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'PREVIEW DA CAPA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.dotaGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 1. Visor Interno do Banner Cinematográfico
          Container(
            height: bannerHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: hasCustomBanner
                    ? AppColors.primaryNeon.withValues(alpha: 0.85)
                    : AppColors.borderHighlight,
                width: 1.5,
              ),
              boxShadow: [
                if (hasCustomBanner)
                  BoxShadow(
                    color: AppColors.primaryNeon.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasCustomBanner)
                  Image.memory(
                    state.bannerBytes!,
                    fit: BoxFit.cover,
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.surfaceHighlight.withValues(alpha: 0.8),
                          AppColors.surface,
                          AppColors.background,
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned(
                          right: -15,
                          top: -15,
                          bottom: -15,
                          width: 240,
                          child: Opacity(
                            opacity: 0.22,
                            child: Image.asset(
                              'assets/images/company_logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Gradiente de Escurecimento Cinematográfico
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.90),
                          Colors.black.withValues(alpha: 0.40),
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),

                // Overlay Dinâmico do Nome do Campeonato
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            AppBadge(
                              label: hasCustomBanner ? 'ARTE PERSONALIZADA' : 'BANNER OFICIAL TSURUS',
                              variant: hasCustomBanner ? AppBadgeVariant.primary : AppBadgeVariant.neutral,
                              fontSize: 10,
                              height: 22,
                            ),
                          ],
                        ),

                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: nameController,
                          builder: (context, value, _) {
                            final typedName = value.text.trim();
                            final displayName = typedName.isEmpty ? 'NOME DO CAMPEONATO' : typedName;
                            final isPlaceholder = typedName.isEmpty;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    displayName.toUpperCase(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: isPlaceholder
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.white,
                                    fontStyle: isPlaceholder ? FontStyle.italic : FontStyle.normal,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.95),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                      if (!isPlaceholder)
                                        Shadow(
                                          color: AppColors.primaryNeon.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.military_tech_rounded,
                                      size: 14,
                                      color: AppColors.dotaGold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${state.teamCount} Equipes • Tsurus Arena Championship',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.dotaGoldLight,
                                        shadows: [
                                          Shadow(color: Colors.black, blurRadius: 4),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Barra de Ações Integrada à Moldura
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.75),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasCustomBanner ? Icons.check_circle_rounded : Icons.shield_rounded,
                  size: 14,
                  color: hasCustomBanner ? AppColors.primaryNeon : AppColors.dotaGold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isUploadingBanner
                        ? 'Enviando e validando banner...'
                        : (hasCustomBanner
                            ? (state.bannerFileName ?? 'Arte personalizada ativa')
                            : 'Banner oficial padrão ativo'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: hasCustomBanner ? FontWeight.w700 : FontWeight.w500,
                      color: hasCustomBanner ? Colors.white : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  text: isUploadingBanner
                      ? 'ENVIANDO...'
                      : (hasCustomBanner ? 'ALTERAR BANNER' : 'SELECIONAR BANNER'),
                  icon: isUploadingBanner ? null : Icons.upload_file_rounded,
                  isLoading: isUploadingBanner,
                  size: AppButtonSize.small,
                  variant: AppButtonVariant.primary,
                  onPressed: isUploadingBanner ? null : onPickBanner,
                ),
                if (hasCustomBanner && !isUploadingBanner) ...[
                  const SizedBox(width: 6),
                  AppButton(
                    text: 'RESTAURAR PADRÃO',
                    icon: Icons.restart_alt_rounded,
                    size: AppButtonSize.small,
                    variant: AppButtonVariant.ghost,
                    onPressed: onRestoreDefault,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 3. Dica Oficial de Upload & Resolução
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Formatos aceitos: PNG, JPG ou WEBP (até 5MB). Resolução recomendada: 1920x1080 (16:9) ou 1920x600 (Mínimo: 960x300).',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
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

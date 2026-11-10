import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/steam_link_controller.dart';

/// Barra de busca acoplada para entrada de SteamID ou Link de perfil.
/// Integra o botão "VERIFICAR" (quando desbloqueada) ou "SOLICITAR TROCA" (quando bloqueada).
class SteamInputSearchBar extends StatelessWidget {
  final SteamLinkController controller;
  final bool isLocked;
  final String? linkedSteamId;
  final VoidCallback onVerify;
  final VoidCallback onRequestUnlock;

  const SteamInputSearchBar({
    super.key,
    required this.controller,
    required this.isLocked,
    this.linkedSteamId,
    required this.onVerify,
    required this.onRequestUnlock,
  });

  @override
  Widget build(BuildContext context) {
    if (isLocked && linkedSteamId != null && linkedSteamId!.isNotEmpty) {
      if (controller.identifierController.text.isEmpty) {
        controller.identifierController.text = linkedSteamId!;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEAMID64 OU LINK DO PERFIL',
          style: AppText.label.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.8),
            fontSize: 11.5,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color:
                isLocked ? AppColors.canvasSurface : AppColors.surfaceHighlight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isLocked
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ícone à esquerda
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  isLocked ? Icons.verified_user_rounded : Icons.search_rounded,
                  size: 20,
                  color: isLocked
                      ? AppColors.primaryNeon
                      : AppColors.textSecondary,
                ),
              ),

              // Campo de Texto
              Expanded(
                child: TextField(
                  controller: controller.identifierController,
                  focusNode: controller.identifierFocus,
                  readOnly: isLocked,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => isLocked ? null : onVerify(),
                  style: TextStyle(
                    color: isLocked ? AppColors.textSecondary : Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    hintText: isLocked
                        ? 'Steam vinculada e protegida'
                        : 'Cole o link do perfil ou SteamID64...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Botão Acoplado à direita
              if (!isLocked) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 5, top: 4, bottom: 4),
                  child: Material(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: controller.isVerifying ? null : onVerify,
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.center,
                        child: controller.isVerifying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 15,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'VERIFICAR',
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.only(right: 5, top: 4, bottom: 4),
                  child: Material(
                    color: controller.isUnlockRequested
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(7),
                    child: InkWell(
                      onTap: (controller.isUnlockRequested ||
                              controller.isRequestingUnlock)
                          ? null
                          : onRequestUnlock,
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.center,
                        decoration: controller.isUnlockRequested
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.6),
                                  width: 1.0,
                                ),
                              )
                            : null,
                        child: controller.isRequestingUnlock
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.0,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    controller.isUnlockRequested
                                        ? Icons.hourglass_top_rounded
                                        : Icons.swap_horiz_rounded,
                                    size: 15,
                                    color: controller.isUnlockRequested
                                        ? AppColors.primaryNeon
                                        : Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    controller.isUnlockRequested
                                        ? 'PENDENTE'
                                        : 'SOLICITAR TROCA',
                                    style: TextStyle(
                                      fontFamily: 'Oswald',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.7,
                                      color: controller.isUnlockRequested
                                          ? AppColors.primaryNeon
                                          : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

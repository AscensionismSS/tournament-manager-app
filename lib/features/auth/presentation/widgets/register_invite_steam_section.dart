import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/register_invite_controller.dart';

/// Seção opcional para busca anônima de perfil Steam e exibição em tempo real do DotaRankMedal
class RegisterInviteSteamSection extends StatelessWidget {
  final RegisterInviteController controller;

  const RegisterInviteSteamSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Future<void> handleVerify() async {
      FocusScope.of(context).unfocus();
      final identifier = controller.steamIdentifierController.text.trim();
      if (identifier.isEmpty) {
        AppFeedback.showWarning(
          context,
          message:
              'Informe o SteamID64 ou o link do perfil Steam para verificar.',
        );
        return;
      }

      await controller.verifySteam();
      if (!context.mounted) return;

      if (controller.steamError != null) {
        AppFeedback.showError(
          context,
          title: 'STEAM NÃO VINCULADA',
          message: controller.steamError!,
        );
      } else if (controller.steamPreview != null) {
        AppFeedback.showSuccess(
          context,
          title: 'PERFIL ENCONTRADO',
          message:
              'Perfil de ${controller.steamPreview!.personaName} identificado com sucesso!',
        );
      }
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sports_esports_rounded,
                    size: 15, color: AppColors.primaryNeon),
                SizedBox(width: 8),
                Text(
                  'CONTA STEAM (OBRIGATÓRIO)',
                  style: TextStyle(
                    fontFamily: 'Oswald',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Campo de entrada da Steam com botão VERIFICAR acoplado
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: controller.steamIdentifierController,
                    hintText: 'SteamID64 ou Link do Perfil',
                    prefixIcon: Icons.link_rounded,
                    textInputAction: TextInputAction.done,
                    onChanged: controller.onSteamIdentifierChanged,
                    onFieldSubmitted: (_) => handleVerify(),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 46,
                  child: AppButton.outline(
                    customColor: AppColors.dotaGold,
                    size: AppButtonSize.medium,
                    text: 'VERIFICAR',
                    isLoading: controller.isVerifyingSteam,
                    onPressed: handleVerify,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Card de Pré-Visualização da Steam (Bloqueia link dinamicamente até verificar)
            SteamPreviewCard(
              preview: controller.steamPreview,
              isVerifying: controller.isVerifyingSteam,
              errorText: controller.steamError,
              onClear: controller.clearSteam,
              currentIdentifier: controller.steamIdentifierController.text,
            ),
          ],
        );
      },
    );
  }
}

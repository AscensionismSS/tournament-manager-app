import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';
import '../../controllers/register_invite_controller.dart';
import 'register_invite_steam_section.dart';

/// Formulário de cadastro por convite com validação de entrada,
/// alternância de visibilidade de senhas e integração da seção Steam.
class RegisterInviteForm extends StatefulWidget {
  final RegisterInviteController controller;
  final VoidCallback onSubmit;

  const RegisterInviteForm({
    super.key,
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<RegisterInviteForm> createState() => _RegisterInviteFormState();
}

class _RegisterInviteFormState extends State<RegisterInviteForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final info = controller.invitationInfo;

    return Form(
      key: controller.formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLogo(),
          const SizedBox(height: 14),

          // Título com identidade oficial TSURUS PLUS+
          const TsurusBrandTitle(
            prefix: 'BEM-VINDO AO',
            stackPrefix: true,
            fontSize: 26,
            textAlign: TextAlign.center,
            letterSpacing: 1.4,
          ),
          const SizedBox(height: 18),

          // Callout com o Papel do Convite (Vermelho Arena com ícone informativo)
          if (info != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryNeon.withValues(alpha: 0.45),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.vpn_key_rounded,
                    size: 16,
                    color: AppColors.primaryNeon,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Convite: ${info.roleDisplayLabel}',
                      style: const TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryNeon,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Tooltip(
                    message:
                        'Todo administrador também possui acesso completo como jogador para disputar torneios e partidas.',
                    triggerMode: TooltipTriggerMode.tap,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.canvasSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.borderHighlight,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.35,
                    ),
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Padding(
                        padding: EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 1. Campo E-mail (Obrigatório digitar para conferência rigorosa no backend)
          AppInput(
            controller: controller.emailController,
            labelText: 'E-mail do Convite',
            hintText: 'Digite o e-mail em que recebeu o convite',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (_) => controller.clearSubmitError(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe o e-mail do convite.';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Informe um e-mail válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 2. Campo Nickname / Display Name
          AppInput(
            controller: controller.displayNameController,
            labelText: 'Seu Nickname na Arena',
            hintText: 'ex: Miracle, Dendi, Shadow',
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.next,
            onChanged: (_) => controller.clearSubmitError(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Informe seu nickname.';
              }
              if (v.trim().length < 2) {
                return 'O nickname deve ter pelo menos 2 caracteres.';
              }
              if (v.trim().length > 32) {
                return 'O nickname não pode ultrapassar 32 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 3. Campo Senha
          AppInput(
            controller: controller.passwordController,
            labelText: 'Senha de Acesso',
            hintText: 'Mínimo de 6 caracteres',
            isPassword: _obscurePassword,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            onChanged: (_) => controller.clearSubmitError(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe uma senha.';
              if (v.length < 6) {
                return 'A senha deve conter ao menos 6 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 4. Campo Confirmação de Senha
          AppInput(
            controller: controller.confirmPasswordController,
            labelText: 'Confirmar Senha',
            hintText: 'Repita sua senha',
            isPassword: _obscureConfirmPassword,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            onChanged: (_) => controller.clearSubmitError(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirme sua senha.';
              if (v != controller.passwordController.text) {
                return 'As senhas não coincidem.';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),

          // 5. Seção Opcional de Vínculo da Steam
          RegisterInviteSteamSection(controller: controller),
          const SizedBox(height: 16),

          // Feedback de erro da API (exibido apenas se houver falha de submissão)
          if (controller.submitError != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.feedbackError.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.feedbackError.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.feedbackError,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.submitError!,
                      style: const TextStyle(
                        color: AppColors.feedbackError,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 6. Botão de Submissão
          AppButton.primary(
            text: 'CRIAR CONTA E ENTRAR',
            isLoading: controller.isSubmitting,
            isFullWidth: true,
            onPressed: widget.onSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.dotaGold.withValues(alpha: 0.7),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.dotaGold.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/company_logo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.shield_rounded,
              size: 40,
              color: AppColors.dotaGold,
            ),
          ),
        ),
      ),
    );
  }
}

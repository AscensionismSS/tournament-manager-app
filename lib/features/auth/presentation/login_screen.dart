import 'package:flutter/material.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/auth_controller.dart';

/// Tela oficial de Login (POST /api/v1/auth/login).
/// Segue a arquitetura Feature-First e Dumb UI:
/// - Cartão central com restrição máxima padronizada de 440px.
/// - Feedback de erros e notificações centralizado exclusivamente via AppFeedback (snack flutuante).
/// - Integração com AppInput e AppButton do Core Shared.
class LoginScreen extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 1. Fecha o teclado virtual ordenadamente antes da requisição
    FocusScope.of(context).unfocus();

    // 2. Validação prévia com listagem detalhada de campos obrigatórios
    final email = _controller.identifierController.text.trim();
    final password = _controller.passwordController.text;

    final invalidFields = <String>[];
    if (email.isEmpty) {
      invalidFields.add('E-mail');
    } else if (!email.contains('@') || !email.contains('.')) {
      invalidFields.add('E-mail (formato válido)');
    }
    if (password.isEmpty) {
      invalidFields.add('Senha');
    }

    if (invalidFields.isNotEmpty) {
      _controller.formKey.currentState?.validate();
      AppFeedback.showError(
        context,
        title: 'CAMPOS OBRIGATÓRIOS',
        message: 'Por favor, preencha: ${invalidFields.join(', ')}.',
      );
      return;
    }

    final success = await _controller.login();
    if (!mounted) return;

    if (success) {
      AppFeedback.showSuccess(
        context,
        title: 'BEM-VINDO!',
        message: 'Autenticado com sucesso no sistema.',
      );
      widget.onLoginSuccess?.call();
    } else if (_controller.errorMessage != null) {
      AppFeedback.showError(
        context,
        title: 'FALHA NO LOGIN',
        message: _controller.errorMessage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        // Ao clicar fora de qualquer campo, recolhe o teclado imediatamente
        behavior: HitTestBehavior.opaque,
        onTap: FocusScope.of(context).unfocus,
        child: AuthBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // Sem efeito elástico para o card não "sambar" na tela
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: DelayedReveal(
                    child: RepaintBoundary(
                      child: AppCard(
                        backgroundOpacity: 0.72,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28.0,
                          vertical: 28.0,
                        ),
                        child: Form(
                          key: _controller.formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Logo Oficial Isolado com RepaintBoundary (Zero jank na GPU/CPU)
                              Center(
                                child: RepaintBoundary(
                                  child: Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primaryNeon
                                            .withValues(alpha: 0.6),
                                        width: 2.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryNeon
                                              .withValues(alpha: 0.25),
                                          blurRadius: 18,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/company_logo.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.shield_rounded,
                                          size: 42,
                                          color: AppColors.primaryNeon,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // 2. Marca Oficial Atualizada
                              const TsurusBrandTitle(
                                fontSize: 23,
                                textAlign: TextAlign.center,
                                letterSpacing: 1.5,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Acesso Restrito da Organização',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),

                              // 3. Campo de E-mail / Usuário (Estático, sem rebuild na digitação)
                              AppInput(
                                controller: _controller.identifierController,
                                labelText: 'E-mail ou Usuário',
                                hintText: 'admin@tournament.local',
                                keyboardType: TextInputType.text,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                prefixIcon: Icons.person_outline_rounded,
                                onChanged: (_) => _controller.clearError(),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Informe o login ou e-mail.';
                                  }
                                  if (value.trim().length > 254) {
                                    return 'O identificador deve ter no máximo 254 caracteres.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // 4. Campo de Senha com Reatividade Focada no Toggle
                              ListenableBuilder(
                                listenable: _controller,
                                builder: (context, _) => AppInput(
                                  controller: _controller.passwordController,
                                  labelText: 'Senha de Acesso',
                                  hintText: '••••••••',
                                  isPassword: !_controller.isPasswordVisible,
                                  textInputAction: TextInputAction.done,
                                  prefixIcon: Icons.lock_outline_rounded,
                                  onChanged: (_) => _controller.clearError(),
                                  onFieldSubmitted: (_) => _handleLogin(),
                                  suffixIcon: IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    icon: Icon(
                                      _controller.isPasswordVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed:
                                        _controller.togglePasswordVisibility,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Informe a sua senha.';
                                    }
                                    if (value.length < 6) {
                                      return 'A senha deve ter no mínimo 6 caracteres.';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // 5. Botão de Ação Primária Reativo
                              ListenableBuilder(
                                listenable: _controller,
                                builder: (context, _) => AppButton(
                                  text: 'Entrar',
                                  onPressed: _controller.isLoading
                                      ? null
                                      : _handleLogin,
                                  isLoading: _controller.isLoading,
                                  isFullWidth: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

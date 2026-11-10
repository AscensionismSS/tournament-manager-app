import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/theme/theme.dart';
import '../controllers/register_invite_controller.dart';
import 'widgets/register_invite_form.dart';
import 'widgets/register_invite_invalid_card.dart';

/// Tela oficial de Registro por Convite (/register?code=...).
/// Componente orquestrador enxuto e responsivo, delegando responsabilidades
/// visuais aos sub-widgets modulares da feature em conformidade estrita com o SRP.
class RegisterInviteScreen extends StatefulWidget {
  final String code;

  const RegisterInviteScreen({
    super.key,
    required this.code,
  });

  @override
  State<RegisterInviteScreen> createState() => _RegisterInviteScreenState();
}

class _RegisterInviteScreenState extends State<RegisterInviteScreen> {
  late final RegisterInviteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegisterInviteController(code: widget.code);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    // 1. Validação prévia com listagem detalhada de campos obrigatórios
    final email = _controller.emailController.text.trim();
    final nick = _controller.displayNameController.text.trim();
    final pass = _controller.passwordController.text;
    final confirm = _controller.confirmPasswordController.text;

    final invalidFields = <String>[];
    if (email.isEmpty) {
      invalidFields.add('E-mail');
    } else if (!email.contains('@') || !email.contains('.')) {
      invalidFields.add('E-mail (formato válido)');
    }

    if (nick.isEmpty) {
      invalidFields.add('Nickname');
    } else if (nick.length < 2) {
      invalidFields.add('Nickname (mínimo 2 letras)');
    }

    if (pass.isEmpty) {
      invalidFields.add('Senha');
    } else if (pass.length < 6) {
      invalidFields.add('Senha (mínimo 6 caracteres)');
    }

    if (confirm.isEmpty) {
      invalidFields.add('Confirmar Senha');
    } else if (pass.isNotEmpty && pass != confirm) {
      invalidFields.add('Confirmação de Senha');
    }

    if (_controller.steamPreview == null) {
      invalidFields.add('Conta Steam');
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

    final result = await _controller.register();
    if (!mounted) return;

    if (result != null) {
      AppFeedback.showSuccess(
        context,
        title: 'CONTA CRIADA COM SUCESSO!',
        message: 'Bem-vindo à Arena, ${result.displayName}!',
      );

      // Redireciona para o destino apropriado
      if (result.canManageTournaments && result.prefersAdminLanding) {
        context.go('/admin/invites');
      } else {
        context.go('/');
      }
    } else if (_controller.submitError != null) {
      AppFeedback.showError(
        context,
        title: 'FALHA NO CADASTRO',
        message: _controller.submitError!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: FocusScope.of(context).unfocus,
        child: AuthBackground(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 28.0),
                        child: _buildBody(),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Estado de Validação Inicial do Convite
    if (_controller.isValidatingCode) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: AppLoadingState(
            message: 'Validando código de convite na Arena...',
          ),
        ),
      );
    }

    // 2. Convite Inválido, Expirado ou Já Consumido
    if (!_controller.isCodeValid) {
      return RegisterInviteInvalidCard(
        errorMessage: _controller.codeValidationError,
      );
    }

    // 3. Formulário de Cadastro Atômico com Validações
    return RegisterInviteForm(
      controller: _controller,
      onSubmit: _handleRegister,
    );
  }
}

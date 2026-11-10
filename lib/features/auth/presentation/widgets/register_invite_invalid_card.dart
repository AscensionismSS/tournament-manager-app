import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/theme/theme.dart';

/// Card exibido quando o convite é inválido, expirou ou já foi consumido.
class RegisterInviteInvalidCard extends StatelessWidget {
  final String? errorMessage;

  const RegisterInviteInvalidCard({
    super.key,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLogo(),
        const SizedBox(height: 16),
        const Text(
          'CONVITE INVÁLIDO',
          style: TextStyle(
            fontFamily: 'Oswald',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.feedbackError.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.feedbackError.withValues(alpha: 0.45),
              width: 1.0,
            ),
          ),
          child: Text(
            errorMessage ?? 'Este link de convite é inválido ou já expirou.',
            style: const TextStyle(
              color: AppColors.feedbackError,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        AppButton.secondary(
          text: 'IR PARA O LOGIN',
          onPressed: () => context.go('/login'),
        ),
      ],
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

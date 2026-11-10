import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Fundo temático das telas de autenticação (login e registro por convite).
/// Imagem em tela cheia com véu escuro para garantir legibilidade do card central.
class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        Image.asset(
          'assets/images/auth_background.png',
          fit: BoxFit.cover,
          cacheWidth: 1920,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
        ColoredBox(color: AppColors.background.withValues(alpha: 0.30)),
        child,
      ],
    );
  }
}

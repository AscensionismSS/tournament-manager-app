import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Indicador de carregamento padronizado para telas, abas e cards (SRP).
class AppLoadingState extends StatelessWidget {
  final String? message;
  final double size;

  const AppLoadingState({
    super.key,
    this.message,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryNeon,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Text(
                message!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Avatar padronizado para usuários, jogadores e membros da plataforma (SRP).
/// Suporta carregamento de foto via URL (rede), asset local, iniciais do nome ou ícone genérico.
class AppAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final String? assetPath;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.assetPath,
    this.radius = 18,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
  });

  /// Factory padronizada para avatares de conta autenticada (Steam com fallback para Logo Tsurus).
  factory AppAvatar.steamOrBrand({
    Key? key,
    String? avatarUrl,
    double size = 32,
  }) {
    final trimmed = avatarUrl?.trim();
    final hasSteam = trimmed != null && trimmed.isNotEmpty;
    return AppAvatar(
      key: key,
      imageUrl: hasSteam ? trimmed : null,
      assetPath: 'assets/images/company_logo.jpg',
      radius: size / 2,
      borderColor: hasSteam
          ? AppColors.dotaGoldLight.withValues(alpha: 0.75)
          : AppColors.primaryNeon.withValues(alpha: 0.6),
      borderWidth: 1.2,
    );
  }

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) return '';
    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0] : '';
      final second = parts[1].isNotEmpty ? parts[1][0] : '';
      return (first + second).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length.clamp(1, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = radius * 2;
    final bg = backgroundColor ?? colorScheme.surfaceContainerHighest;
    final fg = foregroundColor ?? colorScheme.onSurface;
    final border = borderColor ?? colorScheme.outline.withValues(alpha: 0.3);

    Widget content;
    final effectiveUrl = imageUrl?.trim();

    if (effectiveUrl != null && effectiveUrl.isNotEmpty) {
      if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
        content = Image.network(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAssetOrFallback(size, fg),
        );
      } else {
        content = Image.asset(
          effectiveUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAssetOrFallback(size, fg),
        );
      }
    } else {
      content = _buildAssetOrFallback(size, fg);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: border, width: borderWidth),
      ),
      child: ClipOval(
        child: content,
      ),
    );
  }

  Widget _buildAssetOrFallback(double size, Color fg) {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(fg),
      );
    }
    return _buildFallback(fg);
  }

  Widget _buildFallback(Color fg) {
    final initials = _getInitials();
    if (initials.isNotEmpty) {
      return Center(
        child: Text(
          initials,
          style: TextStyle(
            color: fg,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      );
    }
    return Center(
      child: Icon(
        Icons.person_rounded,
        size: radius * 1.1,
        color: fg.withValues(alpha: 0.7),
      ),
    );
  }
}

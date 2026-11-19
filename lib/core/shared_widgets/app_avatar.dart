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

  /// Detecta se a URL é vazia ou corresponde ao avatar genérico "?" padrão da Valve/Steam.
  static bool isGenericSteamPlaceholder(String? url) {
    if (url == null) return true;
    final clean = url.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return clean.contains('fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb') ||
        clean.contains('default_avatar');
  }

  /// Placeholder escuro oficial com o símbolo Tsurus da logo do site (sem letras/iniciais e sem fundo branco).
  static Widget buildTsurusSymbolFallback({required double size}) {
    final int targetCacheSize = (size * 2.0).round().clamp(64, 256);
    return Container(
      width: size,
      height: size,
      color: AppColors.canvasSurface,
      alignment: Alignment.center,
      child: ClipOval(
        child: Image.asset(
          'assets/images/company_logo.jpg',
          width: size,
          height: size,
          cacheWidth: targetCacheSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.sports_esports_rounded,
            size: size * 0.48,
            color: AppColors.primaryNeon.withValues(alpha: 0.75),
          ),
        ),
      ),
    );
  }

  /// Factory padronizada para avatares de conta autenticada (Steam real com fallback para Símbolo Tsurus).
  factory AppAvatar.steamOrBrand({
    Key? key,
    String? avatarUrl,
    double size = 32,
  }) {
    final trimmed = avatarUrl?.trim();
    final hasRealSteamPhoto = !isGenericSteamPlaceholder(trimmed);
    return AppAvatar(
      key: key,
      imageUrl: hasRealSteamPhoto ? trimmed : null,
      assetPath: 'assets/images/company_logo.jpg',
      radius: size / 2,
      borderColor: hasRealSteamPhoto
          ? AppColors.dotaGoldLight.withValues(alpha: 0.75)
          : AppColors.primaryNeon.withValues(alpha: 0.6),
      borderWidth: 1.2,
    );
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
    final int targetCacheSize = (size * 2).round().clamp(32, 256);

    final bool hasValidNetworkUrl = effectiveUrl != null &&
        effectiveUrl.isNotEmpty &&
        !isGenericSteamPlaceholder(effectiveUrl) &&
        (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://'));

    if (hasValidNetworkUrl) {
      content = Image.network(
        effectiveUrl,
        width: size,
        height: size,
        cacheWidth: targetCacheSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildAssetOrFallback(size, targetCacheSize, fg),
      );
    } else if (effectiveUrl != null &&
        effectiveUrl.isNotEmpty &&
        !isGenericSteamPlaceholder(effectiveUrl)) {
      content = Image.asset(
        effectiveUrl,
        width: size,
        height: size,
        cacheWidth: targetCacheSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildAssetOrFallback(size, targetCacheSize, fg),
      );
    } else {
      content = _buildAssetOrFallback(size, targetCacheSize, fg);
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

  Widget _buildAssetOrFallback(double size, int targetCacheSize, Color fg) {
    if (assetPath != null && assetPath!.isNotEmpty) {
      return Image.asset(
        assetPath!,
        width: size,
        height: size,
        cacheWidth: targetCacheSize,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            buildTsurusSymbolFallback(size: size),
      );
    }
    return buildTsurusSymbolFallback(size: size);
  }

}

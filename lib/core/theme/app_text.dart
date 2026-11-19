import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  // Base font styles cacheados em memória (evita centenas de chamadas síncronas ao GoogleFonts por frame)
  static final TextStyle _oswaldBase = GoogleFonts.oswald();
  static final TextStyle _interBase = GoogleFonts.inter();

  // 1. Títulos de Alto Impacto (Oswald Display - Headings)
  /// Títulos Gigantes (Banners, Nomes de Campeonatos Principais)
  static final TextStyle h1 = _oswaldBase.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: 1.2,
  );

  /// Subtítulos e Títulos de Páginas / Abas Principais
  static final TextStyle h2 = _oswaldBase.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 1.0,
  );

  /// Títulos de Cards, Seções e Modais
  static final TextStyle h3 = _oswaldBase.copyWith(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.8,
  );

  /// Subtítulos Compactos e Títulos de Colunas
  static final TextStyle h4 = _oswaldBase.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.6,
  );

  // 2. Tipografia Funcional e de Leitura (Inter - Máxima Legibilidade)
  /// Corpo de Texto Padrão (Descrições, Mensagens, Regras)
  static final TextStyle body = _interBase.copyWith(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  /// Versão Display do Body (Oswald) para compatibilidade retroativa pontual
  static final TextStyle bodyDisplay = _oswaldBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  /// Corpo Intermediário para Tabelas e Listas Densas
  static final TextStyle bodyMedium = _interBase.copyWith(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.45,
  );

  /// Corpo Pequeno para Metadados e Informações Auxiliares (>= 12px)
  static final TextStyle bodySmall = _interBase.copyWith(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface.withValues(alpha: 0.85),
  );

  /// Legendas e Timestamps (>= 11.5px - Nunca abaixo de 11px)
  static final TextStyle caption = _interBase.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface.withValues(alpha: 0.75),
    letterSpacing: 0.3,
  );

  /// Rótulos de Campos e Categorias
  static final TextStyle label = _interBase.copyWith(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.4,
  );

  static final TextStyle _badgeBase = _interBase.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: 0.5,
  );

  /// Tipografia para Badges e Pílulas
  static TextStyle badgeText({Color? color, double fontSize = 11.5}) =>
      _badgeBase.copyWith(
        fontSize: fontSize,
        color: color ?? AppColors.onBackground,
      );

  // 3. Estilos de Ação (Oswald - Botões de Impacto)
  /// Botões de Ação Principais (52px - 56px)
  static final TextStyle button = _oswaldBase.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 1.5,
  );

  static final TextStyle _buttonMediumBase = _oswaldBase.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 1.2,
  );

  /// Botões Intermediários (42px - 48px)
  static TextStyle buttonMedium({Color? color}) =>
      color == null ? _buttonMediumBase : _buttonMediumBase.copyWith(color: color);

  static final TextStyle _buttonDialogBase = _oswaldBase.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 1.2,
  );

  /// Botões de Modais / Diálogos / Sheets (40px - 44px)
  static TextStyle buttonDialog({Color? color}) =>
      color == null ? _buttonDialogBase : _buttonDialogBase.copyWith(color: color);

  static final TextStyle _buttonSmallBase = _oswaldBase.copyWith(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 1.0,
  );

  /// Botões Compactos / Chips / Ações Rápidas (32px - 38px)
  static TextStyle buttonSmall({Color? color}) =>
      color == null ? _buttonSmallBase : _buttonSmallBase.copyWith(color: color);
}

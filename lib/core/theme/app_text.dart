import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppText {
  AppText._();

  // 1. Títulos de Alto Impacto (Oswald Display - Headings)
  /// Títulos Gigantes (Banners, Nomes de Campeonatos Principais)
  static TextStyle get h1 => GoogleFonts.oswald(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: 1.2,
  );

  /// Subtítulos e Títulos de Páginas / Abas Principais
  static TextStyle get h2 => GoogleFonts.oswald(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 1.0,
  );

  /// Títulos de Cards, Seções e Modais
  static TextStyle get h3 => GoogleFonts.oswald(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.8,
  );

  /// Subtítulos Compactos e Títulos de Colunas
  static TextStyle get h4 => GoogleFonts.oswald(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.6,
  );

  // 2. Tipografia Funcional e de Leitura (Inter - Máxima Legibilidade)
  /// Corpo de Texto Padrão (Descrições, Mensagens, Regras)
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 14.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  /// Versão Display do Body (Oswald) para compatibilidade retroativa pontual
  static TextStyle get bodyDisplay => GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  /// Corpo Intermediário para Tabelas e Listas Densas
  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.45,
  );

  /// Corpo Pequeno para Metadados e Informações Auxiliares (>= 12px)
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface.withValues(alpha: 0.85),
  );

  /// Legendas e Timestamps (>= 11.5px - Nunca abaixo de 11px)
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface.withValues(alpha: 0.75),
    letterSpacing: 0.3,
  );

  /// Rótulos de Campos e Categorias
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    letterSpacing: 0.4,
  );

  /// Tipografia para Badges e Pílulas
  static TextStyle badgeText({Color? color, double fontSize = 11.5}) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.onBackground,
    letterSpacing: 0.5,
  );

  // 3. Estilos de Ação (Oswald - Botões de Impacto)
  /// Botões de Ação Principais (52px - 56px)
  static TextStyle get button => GoogleFonts.oswald(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 1.5,
  );

  /// Botões Intermediários (42px - 48px)
  static TextStyle buttonMedium({Color? color}) => GoogleFonts.oswald(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.onPrimary,
    letterSpacing: 1.2,
  );

  /// Botões de Modais / Diálogos / Sheets (40px - 44px)
  static TextStyle buttonDialog({Color? color}) => GoogleFonts.oswald(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.onPrimary,
    letterSpacing: 1.2,
  );

  /// Botões Compactos / Chips / Ações Rápidas (32px - 38px)
  static TextStyle buttonSmall({Color? color}) => GoogleFonts.oswald(
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
    color: color ?? AppColors.onPrimary,
    letterSpacing: 1.0,
  );
}

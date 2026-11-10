import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final baseDark = ThemeData.dark().textTheme;
    final oswaldHeadings = GoogleFonts.oswaldTextTheme(baseDark);
    final interBody = GoogleFonts.interTextTheme(baseDark);

    final combinedTextTheme = interBody.copyWith(
      displayLarge: oswaldHeadings.displayLarge?.copyWith(letterSpacing: 1.2),
      displayMedium: oswaldHeadings.displayMedium?.copyWith(letterSpacing: 1.0),
      displaySmall: oswaldHeadings.displaySmall?.copyWith(letterSpacing: 0.8),
      headlineLarge: oswaldHeadings.headlineLarge?.copyWith(letterSpacing: 1.0),
      headlineMedium: oswaldHeadings.headlineMedium?.copyWith(letterSpacing: 0.8),
      headlineSmall: oswaldHeadings.headlineSmall?.copyWith(letterSpacing: 0.6),
      titleLarge: oswaldHeadings.titleLarge?.copyWith(letterSpacing: 0.6),
      titleMedium: oswaldHeadings.titleMedium?.copyWith(letterSpacing: 0.5),
      titleSmall: oswaldHeadings.titleSmall?.copyWith(letterSpacing: 0.4),
    );

    return ThemeData(
      brightness: Brightness.dark,

      // Mantemos o preto profundo forçado no esqueleto da tela
      scaffoldBackgroundColor: AppColors.background,

      textTheme: combinedTextTheme,

      // ATUALIZAÇÃO MATERIAL 3: Usamos fromSeed e removemos background/onBackground
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary, // A semente base para o motor do M3
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        tertiary: AppColors.primaryNeon, // Vermelho neon fluorescente para destaques e tags especiais
        surface: AppColors.surface, // Assume o papel principal das superfícies
        onSurface: AppColors.onSurface,
        outline: AppColors.border, // Borda sutil padronizada
        error: AppColors.primaryNeon, // Vermelho neon vivo e contrastante
        onError: AppColors.onPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),

      // Centralização do Design System para Botões
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          textStyle: GoogleFonts.oswald(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),

      // Centralização do Design System para Inputs e Campos de Formulário
      // Acabamento gamer com contorno dourado de prestígio (unificado em todos os inputs)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        fillColor: AppColors.surfaceHighlight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.dotaGoldLight,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        hintStyle: TextStyle(
          color: AppColors.onSurface.withValues(alpha: 0.45),
          fontSize: 13.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.dotaGold.withValues(alpha: 0.42),
            width: 1.15,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.dotaGold.withValues(alpha: 0.90),
            width: 1.6,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryNeon,
            width: 1.8,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.primaryNeon,
            width: 1.8,
          ),
        ),
      ),

      // Desativa animações de zoom/cross-fade padrão do Material 3 que causam
      // o efeito 'ghost' (conteúdo da tela anterior visível por trás durante a transição)
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.iOS: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.linux: _NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: _NoAnimationPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Construtor de transição instantânea (zero layout shift, zero atraso ou efeito fantasma)
class _NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

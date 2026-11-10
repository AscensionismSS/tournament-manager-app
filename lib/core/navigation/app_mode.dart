import 'package:flutter/foundation.dart';

/// Modo de navegação da plataforma.
/// Permite que administradores alternem entre a visão de jogador e o painel administrativo.
enum AppMode {
  player,
  admin,
}

/// Estado global reativo de alternância de modo de navegação.
class AppModeState {
  AppModeState._();

  /// Notificador reativo do modo ativo em tempo real
  static final ValueNotifier<AppMode> currentMode =
      ValueNotifier<AppMode>(AppMode.player);

  /// Altera o modo ativo
  static void setMode(AppMode mode) {
    if (currentMode.value != mode) {
      currentMode.value = mode;
    }
  }

  /// Alterna entre modo jogador e modo admin
  static void toggle() {
    currentMode.value = currentMode.value == AppMode.player
        ? AppMode.admin
        : AppMode.player;
  }

  static bool get isPlayer => currentMode.value == AppMode.player;
  static bool get isAdmin => currentMode.value == AppMode.admin;
}

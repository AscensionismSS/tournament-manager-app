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

  /// Última rota navegada no painel administrativo (padrão: Convites de Acesso)
  static String lastAdminRoute = '/admin/invites';

  /// Última rota navegada no modo jogador (padrão: Início / Dashboard)
  static String lastPlayerRoute = '/';

  /// Registra a rota atual para memorizar com fidelidade a tela ativa de cada modo
  static void recordRoute(String route) {
    final uri = Uri.tryParse(route);
    final path = uri?.path ?? route;
    final isFromAdmin = uri?.queryParameters['from'] == 'admin';

    if (path.startsWith('/admin') || (isFromAdmin && path.startsWith('/tournaments'))) {
      lastAdminRoute = route;
    } else if (path == '/' ||
        path.startsWith('/tournaments') ||
        path.startsWith('/members')) {
      lastPlayerRoute = route;
    }
  }

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

  /// Limpa o estado de navegação em memória ao encerrar a sessão (Logout / 401)
  static void reset() {
    lastAdminRoute = '/admin/invites';
    lastPlayerRoute = '/';
    currentMode.value = AppMode.player;
  }

  static bool get isPlayer => currentMode.value == AppMode.player;
  static bool get isAdmin => currentMode.value == AppMode.admin;
}

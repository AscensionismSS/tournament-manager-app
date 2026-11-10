import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/system_security_settings.dart';
import '../../../core/navigation/app_mode.dart';
import '../../../core/network/signalr_service.dart';
import '../../../core/network/tournament_events_service.dart';
import '../../../core/network/tournament_webhook_event_dto.dart';
import '../../../core/services/system_security_service.dart';
import '../../../core/shared_widgets/shared_widgets.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/theme.dart';
import '../../auth/presentation/steam_config_dialog.dart';
import 'desktop_sidebar.dart';
import 'desktop_top_bar.dart';

/// Orquestrador Raiz da Navegação (MainShell).
/// - A NavBar (TopBar) ocupa a linha reta horizontal toda (100% de largura) com logo fixo.
/// - O botão hambúrguer expande a SideBar no espaço ABAIXO da NavBar.
/// - A SideBar desliza suavemente sobre o conteúdo sem empurrar a tela (zero layout shift).
/// - A NavBar e seu logo/perfil nunca são cobertos pela SideBar.
/// - Valida e dispara o Modal Obrigatório de Configurar Steam caso o usuário logado ainda não tenha vinculado.
/// - Conecta e gerencia o ciclo de vida do SignalR Hub para eventos em tempo real.
class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isSidebarOpen = false;
  bool _isSteamCheckDone = false;
  StreamSubscription<TournamentWebhookEventDto>? _sseSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSteamLinkStatus();
      TournamentEventsService.instance.startGlobalStream();
      _sseSubscription =
          TournamentEventsService.instance.events.listen(_onTournamentEvent);
      SignalRService.instance.connect();
      SystemSecurityService.instance.init();
    });
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    TournamentEventsService.instance.stopGlobalStream();
    SignalRService.instance.stop();
    super.dispose();
  }

  void _onTournamentEvent(TournamentWebhookEventDto evt) {
    if (evt.eventType == 'SecuritySettingsUpdated') {
      SystemSecurityService.instance.fetchSettings();
    }

    if (!mounted || evt.message.isEmpty) return;

    if (evt.isWarningEvent) {
      AppFeedback.showWarning(
        context,
        title: evt.tournamentName.toUpperCase(),
        message: evt.message,
      );
    } else if (evt.isHighlightEvent) {
      AppFeedback.showSuccess(
        context,
        title: evt.tournamentName.toUpperCase(),
        message: evt.message,
      );
    } else {
      AppFeedback.showInfo(
        context,
        title: evt.tournamentName.toUpperCase(),
        message: evt.message,
      );
    }
  }

  Future<void> _checkSteamLinkStatus() async {
    if (_isSteamCheckDone || !mounted) return;
    _isSteamCheckDone = true;

    final profile = await TokenStorage.getUserProfile();
    if (profile != null && !profile.isSteamLinked && mounted) {
      await SteamConfigDialog.show(
        context,
        isMandatory: true,
        currentProfile: profile,
      );
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarOpen = !_isSidebarOpen;
    });
  }

  void _closeSidebar() {
    if (_isSidebarOpen) {
      setState(() {
        _isSidebarOpen = false;
      });
    }
  }

  String _resolveTitle(String route) {
    if (route == '/admin/invites') return 'Convites de Acesso';
    if (route == '/admin/tournaments') return 'Criador de Torneios';
    if (route == '/admin/members') return 'Gestão de Membros & Permissões';
    if (route == '/tournaments') return 'Torneios';
    if (route.startsWith('/tournaments/')) {
      if (route.endsWith('/teams')) return 'Torneio • Equipes';
      if (route.endsWith('/groups')) return 'Torneio • Tabela de Grupos';
      if (route.endsWith('/matches')) return 'Torneio • Partidas de Grupos';
      if (route.endsWith('/playoffs')) return 'Torneio • Playoffs';
      if (route.endsWith('/draft')) return 'Torneio • Draft & Gestão de Times';
      return 'Torneio • Visão Geral';
    }
    if (route.startsWith('/members') || route.startsWith('/teams')) return 'Membros';
    return AppModeState.isAdmin ? 'Convites de Acesso' : 'Início / Dashboard';
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final title = _resolveTitle(currentRoute);
    const sidebarWidth = 250.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. NavBar Fixa de ponta a ponta (100% da largura superior com Logo e TSURUS PLUS+)
              DesktopTopBar(
                isSidebarOpen: _isSidebarOpen,
                onToggleSidebar: _toggleSidebar,
                title: title,
              ),

              // 2. Banner Global de Manutenção (Dumb UI reativa)
              ValueListenableBuilder<SystemSecuritySettings>(
                valueListenable: SystemSecurityService.instance.settingsNotifier,
                builder: (context, settings, _) {
                  if (!settings.maintenanceMode) {
                    return const SizedBox.shrink();
                  }
                  return GlobalNoticeBanner(
                    message: settings.message,
                  );
                },
              ),

              // 3. Área útil abaixo da NavBar: O conteúdo ocupa 100% da tela sem ser empurrado.
              // A SideBar desliza por cima (overlay) suavemente, eliminando layout shift e lag de reflow.
              Expanded(
                child: Stack(
                  children: [
                    // Conteúdo da página ocupa sempre a largura total
                    Positioned.fill(
                      child: widget.child,
                    ),

                    // Backdrop suave translúcido quando a SideBar estiver aberta
                    if (_isSidebarOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _closeSidebar,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ),

                    // SideBar deslizando por cima do conteúdo (Overlay)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 230),
                      curve: Curves.easeOutCubic,
                      left: _isSidebarOpen ? 0 : -sidebarWidth,
                      top: 0,
                      bottom: 0,
                      width: sidebarWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: _isSidebarOpen
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.60),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                    offset: const Offset(4, 0),
                                  ),
                                ]
                              : null,
                        ),
                        child: DesktopSidebar(
                          currentRoute: currentRoute,
                          onNavigate: _closeSidebar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

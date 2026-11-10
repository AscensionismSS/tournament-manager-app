import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/invitations/presentation/invitations_admin_screen.dart';
import '../../features/admin/members/controllers/admin_members_controller.dart';
import '../../features/admin/members/presentation/admin_members_screen.dart';
import '../../features/tournaments/models/tournament_dto.dart';
import '../../features/admin/tournaments/presentation/admin_tournaments_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_invite_screen.dart';
import '../../features/draft/presentation/draft_room_screen.dart';
import '../../features/members/presentation/members_screen.dart';
import '../../features/shell/presentation/main_shell.dart';
import '../../features/tournaments/controllers/tournament_details_controller.dart';
import '../../features/tournaments/presentation/tournament_details_screen.dart';
import '../../features/tournaments/presentation/tournaments_screen.dart';
import '../storage/token_storage.dart';
import '../shared_widgets/shared_widgets.dart';
import 'app_mode.dart';

/// Gerenciador central de rotas e navegação da aplicação via [GoRouter].
class AppRouter {
  AppRouter._();

  /// Chave global de navegação raiz, permitindo que o [AppFeedback]
  /// injete notificações no nível mais alto do Overlay da árvore de widgets.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  /// Configuração de rotas da aplicação
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) async {
      final hasToken = await TokenStorage.hasToken();
      final isLoggingIn = state.matchedLocation == '/login';
      final isPublicRoute = isLoggingIn ||
          state.matchedLocation.startsWith('/register');

      // 1. Bloqueia acesso a rotas privadas se o usuário não tiver token
      if (!hasToken && !isPublicRoute) {
        return '/login';
      }

      // 2. Se já autenticado e estiver no login, redireciona para a tela inicial adequada
      if (hasToken && isLoggingIn) {
        final profile = await TokenStorage.getUserProfile();
        if (profile != null && profile.canManageTournaments && profile.prefersAdminLanding) {
          AppModeState.setMode(AppMode.admin);
          return '/admin/invites';
        } else {
          AppModeState.setMode(AppMode.player);
          return '/';
        }
      }

      // 3. Proteção Estrita RBAC (Role-Based Access Control): Rotas /admin exclusivas para Administradores
      if (hasToken && state.matchedLocation.startsWith('/admin')) {
        final profile = await TokenStorage.getUserProfile();
        if (profile == null || !profile.canManageTournaments) {
          // Jogador comum tentando acessar painel de admin -> redireciona para a raiz
          AppModeState.setMode(AppMode.player);
          return '/';
        }
        AppModeState.setMode(AppMode.admin);
      } else if (hasToken && !isPublicRoute) {
        final isFromAdmin = state.uri.queryParameters['from'] == 'admin';
        if (isFromAdmin) {
          final profile = await TokenStorage.getUserProfile();
          if (profile != null && profile.canManageTournaments) {
            AppModeState.setMode(AppMode.admin);
          } else {
            AppModeState.setMode(AppMode.player);
          }
        } else {
          // Sincroniza automaticamente a Sidebar para o Modo Jogador ao navegar para /tournaments, /members ou /
          AppModeState.setMode(AppMode.player);
        }
      }

      return null;
    },
    routes: [
      // 1. Rota de Autenticação (Fora do Shell) - Tela Principal inicial
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildSubtleFadePage(
          key: state.pageKey,
          child: LoginScreen(
            onLoginSuccess: () async {
              final profile = await TokenStorage.getUserProfile();
              if (profile != null && profile.canManageTournaments && profile.prefersAdminLanding) {
                AppModeState.setMode(AppMode.admin);
                if (context.mounted) context.go('/admin/invites');
              } else {
                AppModeState.setMode(AppMode.player);
                if (context.mounted) context.go('/');
              }
            },
          ),
        ),
      ),

      // 1.1 Rota Pública de Cadastro por Convite (Fora do Shell)
      GoRoute(
        path: '/register',
        name: 'register',
        pageBuilder: (context, state) {
          final code = state.uri.queryParameters['code'] ?? '';
          return _buildSubtleFadePage(
            key: state.pageKey,
            child: RegisterInviteScreen(code: code),
          );
        },
      ),

      // 2. Rotas Autenticadas (Dentro do Shell com Sidebar, TopBar e Mobile Drawer)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => _buildSubtleFadePage(
              key: state.pageKey,
              child: const _AppPlaceholderScreen(
                title: 'Dashboard Geral',
                message: 'Visão consolidada de torneios e partidas da arena.',
                icon: Icons.sports_esports_rounded,
              ),
            ),
          ),
          GoRoute(
            path: '/tournaments',
            name: 'tournaments',
            pageBuilder: (context, state) => _buildSubtleFadePage(
              key: state.pageKey,
              child: const TournamentsScreen(),
            ),
          ),
          GoRoute(
            path: '/tournaments/:id',
            name: 'tournament_details',
            redirect: (context, state) {
              final tournamentId = state.pathParameters['id'] ?? '';
              final tabQuery = state.uri.queryParameters['tab'] ?? 'overview';
              final fromQuery = state.uri.queryParameters['from'];
              final queryString = fromQuery != null ? '?from=$fromQuery' : '';
              return '/tournaments/$tournamentId/$tabQuery$queryString';
            },
          ),
          // 2.1 Sala de Draft Oficial (Acesso em tela cheia com prioridade sobre o seletor genérico de abas)
          GoRoute(
            path: '/tournaments/:id/draft-room',
            name: 'tournament_draft_room',
            pageBuilder: (context, state) {
              final tournamentId = state.pathParameters['id'] ?? '';
              final extraTournament = state.extra is TournamentDto
                  ? state.extra as TournamentDto
                  : null;
              return _buildSubtleFadePage(
                key: ValueKey('draft_room_$tournamentId'),
                child: DraftRoomScreen(
                  tournamentId: tournamentId,
                  initialTournament: extraTournament,
                ),
              );
            },
          ),
          GoRoute(
            path: '/tournaments/:id/:tab',
            name: 'tournament_details_tab',
            pageBuilder: (context, state) {
              final tournamentId = state.pathParameters['id'] ?? '';
              final tabSlug = state.pathParameters['tab'];
              final extraTournament = state.extra is TournamentDto
                  ? state.extra as TournamentDto
                  : null;
              return _buildSubtleFadePage(
                key: ValueKey('tournament_details_$tournamentId'),
                child: TournamentDetailsScreen(
                  tournamentId: tournamentId,
                  initialTournament: extraTournament,
                  initialTab: TournamentDetailTab.fromSlug(tabSlug),
                ),
              );
            },
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            pageBuilder: (context, state) => _buildSubtleFadePage(
              key: state.pageKey,
              child: const MembersScreen(),
            ),
          ),
          GoRoute(
            path: '/teams',
            redirect: (context, state) => '/members',
          ),
          GoRoute(
            path: '/matches',
            redirect: (context, state) => '/tournaments',
          ),
          GoRoute(
            path: '/admin',
            redirect: (context, state) => '/admin/invites',
          ),
          GoRoute(
            path: '/admin/invites',
            name: 'admin_invites',
            pageBuilder: (context, state) => _buildSubtleFadePage(
              key: state.pageKey,
              child: const InvitationsAdminScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/members',
            name: 'admin_members',
            pageBuilder: (context, state) {
              final tabParam = state.uri.queryParameters['tab'];
              final initialTab = (tabParam == 'requests' || tabParam == 'recovery')
                  ? AdminMembersTab.recoveryRequests
                  : AdminMembersTab.members;

              return _buildSubtleFadePage(
                key: const ValueKey('admin_members_page'),
                child: AdminMembersScreen(
                  initialTab: initialTab,
                ),
              );
            },
          ),
          GoRoute(
            path: '/admin/tournaments',
            name: 'admin_tournaments',
            pageBuilder: (context, state) => _buildSubtleFadePage(
              key: state.pageKey,
              child: const AdminTournamentsScreen(),
            ),
          ),
          GoRoute(
            path: '/admin/settings',
            redirect: (context, state) => '/admin/invites',
          ),
        ],
      ),
    ],
  );
}

/// Transição suave e sutil (apenas fade leve de 140ms, sem escala ou distorção de fundo)
CustomTransitionPage<T> _buildSubtleFadePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 140),
    reverseTransitionDuration: const Duration(milliseconds: 140),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}



/// Tela de placeholder limpa utilizando o componente oficial AppEmptyState
class _AppPlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const _AppPlaceholderScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AppEmptyState(
            icon: icon,
            title: title,
            message: message,
            asCard: true,
          ),
        ),
      ),
    );
  }
}

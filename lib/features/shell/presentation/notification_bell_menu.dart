import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/tournament_events_service.dart';
import '../../../core/network/tournament_webhook_event_dto.dart';
import '../../../core/theme/theme.dart';

/// Menu Suspenso do Sininho de Notificações em Tempo Real (SSE Global).
/// Escuta `TournamentEventsService.instance.notifications`, acende a bolinha vermelha
/// quando há eventos novos e permite navegar direto para o campeonato clicado.
class NotificationBellMenu extends StatelessWidget {
  const NotificationBellMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TournamentEventsService.instance;

    return ValueListenableBuilder<List<TournamentWebhookEventDto>>(
      valueListenable: service.notifications,
      builder: (context, items, _) {
        final unread = items.where((e) => !e.isRead).length;
        final hasUnread = unread > 0;

        return PopupMenuButton<String>(
          tooltip: 'Notificações de Campeonatos',
          offset: const Offset(0, 48),
          color: AppColors.surface,
          constraints: const BoxConstraints(
            minWidth: 330,
            maxWidth: 380,
            maxHeight: 460,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          onOpened: service.markAllAsRead,
          onSelected: (value) {
            if (value == '__clear__') {
              service.clearAll();
              return;
            }
            if (value.isNotEmpty) {
              context.go('/tournaments/$value/overview');
            }
          },
          itemBuilder: (context) => [
            // 1. Cabeçalho do Sininho
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 10, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        size: 16,
                        color: AppColors.dotaGold,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'NOTIFICAÇÕES DA ARENA',
                          style: TextStyle(
                            fontFamily: 'Oswald',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      if (items.isNotEmpty)
                        InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () {
                            service.clearAll();
                            Navigator.of(context).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              'LIMPAR',
                              style: TextStyle(
                                color: AppColors.primaryNeon.withValues(
                                  alpha: 0.9,
                                ),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.border, height: 1),
                ],
              ),
            ),

            // 2. Estado Vazio ou Lista de Eventos Recebidos
            if (items.isEmpty)
              const PopupMenuItem<String>(
                enabled: false,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_paused_rounded,
                      size: 28,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma atualização no momento',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Avisos de início de campeonatos, séries e playoffs aparecerão aqui em tempo real.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...items.take(10).map(
                    (evt) => PopupMenuItem<String>(
                      value: evt.tournamentId,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: _NotificationItemTile(event: evt),
                    ),
                  ),
          ],
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.14)
                  : AppColors.canvasSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasUnread
                    ? AppColors.primaryNeon.withValues(alpha: 0.55)
                    : AppColors.border,
                width: 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  hasUnread
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 20,
                  color: hasUnread
                      ? AppColors.dotaGoldLight
                      : AppColors.textSecondary,
                ),
                // Bolinha vermelha de não lido no canto superior direito do Sininho
                if (hasUnread)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNeon,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                          color: AppColors.navSurface,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryNeon.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NotificationItemTile extends StatelessWidget {
  final TournamentWebhookEventDto event;

  const _NotificationItemTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final accentColor = event.isWarningEvent
        ? AppColors.feedbackWarning
        : event.isHighlightEvent
            ? AppColors.dotaGold
            : AppColors.primaryNeon;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: event.isRead
              ? AppColors.border.withValues(alpha: 0.6)
              : accentColor.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: accentColor.withValues(alpha: 0.35)),
            ),
            child: Icon(event.eventIcon, size: 15, color: accentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.tournamentName.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      event.formattedTime,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

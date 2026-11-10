import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/system_security_service.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../core/storage/token_storage.dart';
import '../../controllers/matches_controller.dart';
import '../../controllers/tournament_details_controller.dart';
import '../../models/match_series_dto.dart';
import '../../models/tournament_dto.dart';
import '../../models/tournament_status.dart';
import 'match_details/game_manual_result_dialog.dart';
import 'match_details/game_result_type_dialog.dart';
import 'match_details/game_walkover_dialog.dart';

/// Orquestrador desacoplado de diálogos e ações de Campeonato (SRP & Dumb UI).
/// Isola a apresentação e controle de modais para manter as telas enxutas e focadas em composição.
class TournamentActionDialogs {
  TournamentActionDialogs._();

  /// Ação de inscrição de equipe ou aviso de pool de draft
  static Future<void> register(
    BuildContext context,
    TournamentDetailsController controller,
    TournamentDto tournament,
  ) async {
    if (SystemSecurityService.instance.isTournamentRegistrationLocked) {
      final msg = SystemSecurityService.instance.message;
      AppFeedback.showWarning(
        context,
        title: 'INSCRIÇÕES BLOQUEADAS',
        message: (msg != null && msg.trim().isNotEmpty)
            ? msg.trim()
            : 'As inscrições de torneios estão temporariamente bloqueadas pela administração do sistema.',
      );
      return;
    }

    if (tournament.hasDraftSession) {
      final user = await TokenStorage.getUserProfile();
      if (user == null) {
        if (!context.mounted) return;
        AppFeedback.showWarning(
          context,
          title: 'AUTENTICAÇÃO NECESSÁRIA',
          message: 'Você precisa estar autenticado para se inscrever neste campeonato.',
        );
        return;
      }

      final alreadyInPool = tournament.draftPlayerPool.any(
        (p) =>
            p.id == user.userId ||
            (p.externalUserId != null &&
                user.steamId != null &&
                p.externalUserId == user.steamId),
      );

      if (alreadyInPool) {
        if (!context.mounted) return;
        final wantToCancel = await AppConfirmDialog.show(
          context,
          title: 'INSCRIÇÃO CONFIRMADA',
          message:
              'Você já está inscrito no pool de jogadores deste campeonato. Deseja cancelar sua inscrição?',
          confirmLabel: 'CANCELAR INSCRIÇÃO',
          cancelLabel: 'MANTER INSCRIÇÃO',
          icon: Icons.check_circle_rounded,
        );

        if (wantToCancel && context.mounted) {
          final error = await controller.removeCurrentPlayerFromDraftPool();
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Inscrição cancelada com sucesso.',
            );
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        return;
      }

      if (!context.mounted) return;
      final confirm = await AppConfirmDialog.show(
        context,
        title: 'INSCREVER-SE NO DRAFT',
        message:
            'Deseja confirmar sua inscrição individual no pool de draft do campeonato "${tournament.name}"?',
        confirmLabel: 'CONFIRMAR INSCRIÇÃO',
        cancelLabel: 'CANCELAR',
        icon: Icons.how_to_reg_rounded,
      );

      if (confirm && context.mounted) {
        final error = await controller.registerCurrentPlayerToDraft();
        if (!context.mounted) return;
        if (error == null) {
          AppFeedback.showSuccess(
            context,
            message: 'Inscrição realizada com sucesso no pool do draft!',
          );
        } else {
          AppFeedback.showError(context, message: error);
        }
      }
      return;
    }

    final teamName = await AppPromptDialog.show(
      context,
      title: 'INSCREVER EQUIPE',
      message:
          'Informe o nome oficial da equipe para ocupar uma vaga neste campeonato:',
      hintText: 'Ex: Team Spirit, Tsurus Gaming...',
      confirmLabel: 'INSCREVER EQUIPE',
      icon: Icons.shield_rounded,
      isRequired: true,
      maxLines: 1,
      maxLength: 50,
    );

    if (teamName != null && teamName.trim().isNotEmpty && context.mounted) {
      final error = await controller.addTeam(teamName);
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Equipe "$teamName" inscrita com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Abrir inscrições do campeonato
  static Future<void> openRegistrations(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'ABRIR INSCRIÇÕES',
      message: 'Deseja abrir as inscrições deste campeonato para os jogadores agora?',
      confirmLabel: 'ABRIR INSCRIÇÕES',
      cancelLabel: 'CANCELAR',
      icon: Icons.lock_open_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.openRegistrations();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Inscrições abertas com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Travar inscrições do campeonato ou iniciar o Draft
  static Future<void> closeRegistrations(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final t = controller.tournament;
    final isDraft = t?.hasDraftSession ?? false;

    final confirm = await AppConfirmDialog.show(
      context,
      title: isDraft ? 'INICIAR FASE DE DRAFT' : 'TRAVAR INSCRIÇÕES',
      message: isDraft
          ? 'Deseja encerrar as inscrições e iniciar a fase de Draft agora? As inscrições serão travadas para todos os jogadores.'
          : 'Deseja encerrar as inscrições deste campeonato agora?',
      confirmLabel: isDraft ? 'INICIAR DRAFT' : 'TRAVAR INSCRIÇÕES',
      cancelLabel: 'CANCELAR',
      icon: isDraft ? Icons.shuffle_rounded : Icons.lock_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.closeRegistrations();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: isDraft
              ? 'Inscrições encerradas com sucesso! A fase de Draft foi iniciada.'
              : 'Inscrições encerradas com sucesso!',
        );
        if (isDraft && t != null && context.mounted) {
          await openDraftRoom(context, t);
        }
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Iniciar campeonato
  static Future<void> startTournament(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'INICIAR CAMPEONATO',
      message: 'Deseja iniciar o campeonato e gerar as séries de confrontos?',
      confirmLabel: 'INICIAR AGORA',
      cancelLabel: 'CANCELAR',
      icon: Icons.play_arrow_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.startTournament();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Campeonato iniciado com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Gerar chaves dos playoffs a partir da fase de grupos
  static Future<void> advanceToPlayoffs(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'GERAR CHAVES DOS PLAYOFFS',
      message:
          'Deseja encerrar a Fase de Grupos e gerar as chaves dos Playoffs com base na classificação oficial atual?',
      confirmLabel: 'GERAR AGORA',
      cancelLabel: 'CANCELAR',
      icon: Icons.play_arrow_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.advanceToPlayoffs();
      if (!context.mounted) return;
      if (error == null) {
        controller.setActiveTab(TournamentDetailTab.playoffs);
        AppFeedback.showSuccess(
          context,
          message: 'Chaves dos Playoffs geradas com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Reverter playoffs para a fase de grupos
  static Future<void> revertToGroupStage(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'REVERTER PARA FASE DE GRUPOS',
      message:
          'Atenção: Reverter para a fase de grupos resetará os confrontos dos playoffs gerados. Deseja continuar?',
      confirmLabel: 'SIM, REVERTER',
      cancelLabel: 'CANCELAR',
      isDestructive: true,
      icon: Icons.warning_amber_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.revertToGroupStage();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Campeonato revertido para a Fase de Grupos com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Cancelar campeonato
  static Future<void> cancelTournament(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'CANCELAR CAMPEONATO',
      message:
          'Deseja realmente cancelar este campeonato? O torneio será travado e o lançamento de resultados será bloqueado.',
      confirmLabel: 'CANCELAR CAMPEONATO',
      cancelLabel: 'VOLTAR',
      isDestructive: true,
      icon: Icons.cancel_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.cancelTournament();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Campeonato cancelado com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Excluir campeonato
  static Future<void> deleteTournament(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'EXCLUIR CAMPEONATO',
      message:
          'ATENÇÃO: Deseja realmente excluir este campeonato? Todas as séries, mapas, confrontos e o draft vinculado serão permanentemente removidos.',
      confirmLabel: 'EXCLUIR DEFINITIVAMENTE',
      cancelLabel: 'VOLTAR',
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.deleteTournament();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Campeonato excluído com sucesso!',
        );
        context.go('/tournaments');
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Redirecionar para a sala de draft
  static Future<void> openDraftRoom(
    BuildContext context,
    TournamentDto tournament,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'ABRIR DRAFT & GESTÃO DE TIMES?',
      message:
          'Você será redirecionado para o painel de Draft & Gestão de Times em tela cheia. Deseja continuar?',
      confirmLabel: 'ABRIR AGORA',
      cancelLabel: 'CANCELAR',
      icon: Icons.shuffle_rounded,
    );

    if (confirmed == true && context.mounted) {
      final canManage =
          TokenStorage.profileNotifier.value?.canManageTournaments ?? false;
      final isFromAdmin = GoRouterState.of(context).uri.queryParameters['from'] == 'admin' ||
          canManage;
      final query = isFromAdmin ? '?from=admin' : '';
      context.go('/tournaments/${tournament.id}/draft-room$query', extra: tournament);
    }
  }

  /// Travar envio de resultados (Result Submission Lock)
  static Future<void> lockResults(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final reason = await AppPromptDialog.show(
      context,
      title: 'TRAVAR ENVIO DE RESULTADOS',
      message:
          'Informe o motivo para suspender o lançamento e edição de resultados das partidas deste campeonato:',
      hintText: 'Ex: Auditoria em andamento, pausa técnica, recurso...',
      confirmLabel: 'TRAVAR RESULTADOS',
      cancelLabel: 'CANCELAR',
      icon: Icons.lock_clock_rounded,
      isRequired: false,
      maxLines: 2,
      maxLength: 200,
    );

    if (reason != null && context.mounted) {
      final error = await controller.lockResultSubmission(reason);
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Envio de resultados travado com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Destravar envio de resultados (Result Submission Unlock)
  static Future<void> unlockResults(
    BuildContext context,
    TournamentDetailsController controller,
  ) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'DESTRAVAR ENVIO DE RESULTADOS',
      message:
          'Deseja liberar novamente o lançamento e a edição de resultados para este campeonato?',
      confirmLabel: 'LIBERAR RESULTADOS',
      cancelLabel: 'CANCELAR',
      icon: Icons.lock_open_rounded,
    );

    if (confirm && context.mounted) {
      final error = await controller.unlockResultSubmission();
      if (!context.mounted) return;
      if (error == null) {
        AppFeedback.showSuccess(
          context,
          message: 'Envio de resultados liberado com sucesso!',
        );
      } else {
        AppFeedback.showError(context, message: error);
      }
    }
  }

  /// Registrar novo resultado de mapa
  static Future<void> recordResult(
    BuildContext context,
    TournamentDetailsController controller,
    MatchSeriesDto match,
    int gameIndex,
  ) async {
    final t = controller.tournament;
    final bool isGlobalLocked =
        SystemSecurityService.instance.isResultSubmissionLocked;
    final bool isTournamentLocked = t?.isResultSubmissionLocked == true;
    if (isGlobalLocked || isTournamentLocked) {
      final msg = isGlobalLocked
          ? ((SystemSecurityService.instance.message != null &&
                  SystemSecurityService.instance.message!.trim().isNotEmpty)
              ? SystemSecurityService.instance.message!.trim()
              : 'O envio e alteração de resultados de partidas está temporariamente bloqueado pela administração do sistema.')
          : t!.resultLockReasonLabel;
      AppFeedback.showWarning(
        context,
        title: 'ENVIO DE RESULTADOS BLOQUEADO',
        message: msg,
      );
      return;
    }

    if (t != null) {
      if (t.isRegistrationOpen) {
        AppFeedback.showWarning(
          context,
          message:
              'Não é possível registrar resultados em um campeonato que ainda não foi iniciado.',
        );
        return;
      }
      if (t.status == TournamentStatus.canceled) {
        AppFeedback.showWarning(
          context,
          message: 'Este campeonato foi cancelado e não aceita mais resultados.',
        );
        return;
      }
    }

    final type = await GameResultTypeDialog.show(
      context,
      series: match,
      gameNumber: gameIndex,
    );
    if (type == null || !context.mounted) return;

    final matchesController = MatchesController(initialSeries: match);

    switch (type) {
      case GameResultType.manual:
        final result = await GameManualResultDialog.show(
          context,
          series: match,
          gameNumber: gameIndex,
        );
        if (result != null && context.mounted) {
          final error = await matchesController.recordManualResult(
            matchId: match.id,
            gameNumber: gameIndex,
            winnerTeamId: result['winnerTeamId'] as String,
            durationSeconds: result['durationSeconds'] as int,
            teamAKills: result['teamAKills'] as int,
            teamBKills: result['teamBKills'] as int,
            firstPickTeamId: result['firstPickTeamId'] as String?,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Resultado do Game #$gameIndex registrado com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.replay:
        final picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['dem', 'zip'],
          withData: true,
        );
        if (picked != null && picked.files.isNotEmpty && context.mounted) {
          final file = picked.files.first;
          if (file.bytes == null) {
            AppFeedback.showError(context, message: 'Arquivo inválido ou vazio.');
            return;
          }
          AppFeedback.showInfo(
            context,
            message: 'Enviando e processando replay (${file.name})...',
          );
          final error = await matchesController.uploadReplay(
            matchId: match.id,
            fileBytes: file.bytes!,
            fileName: file.name,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Replay processado com sucesso pelo parser oficial!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.walkover:
        final winnerId = await GameWalkoverDialog.show(
          context,
          series: match,
          gameNumber: gameIndex,
        );
        if (winnerId != null && context.mounted) {
          final error = await matchesController.updateGameWalkover(
            matchId: match.id,
            gameNumber: gameIndex,
            winnerTeamId: winnerId,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message:
                  'Vitória por W.O. aplicada com sucesso no Game #$gameIndex!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.undoLastGame:
      case GameResultType.rollback:
        break;
    }
  }

  /// Editar resultado existente de mapa
  static Future<void> editResult(
    BuildContext context,
    TournamentDetailsController controller,
    MatchSeriesDto match,
    int gameIndex,
  ) async {
    final t = controller.tournament;
    final bool isGlobalLocked =
        SystemSecurityService.instance.isResultSubmissionLocked;
    final bool isTournamentLocked = t?.isResultSubmissionLocked == true;
    if (isGlobalLocked || isTournamentLocked) {
      final msg = isGlobalLocked
          ? ((SystemSecurityService.instance.message != null &&
                  SystemSecurityService.instance.message!.trim().isNotEmpty)
              ? SystemSecurityService.instance.message!.trim()
              : 'O envio e alteração de resultados de partidas está temporariamente bloqueado pela administração do sistema.')
          : t!.resultLockReasonLabel;
      AppFeedback.showWarning(
        context,
        title: 'ENVIO DE RESULTADOS BLOQUEADO',
        message: msg,
      );
      return;
    }

    if (t != null) {
      if (t.isRegistrationOpen) {
        AppFeedback.showWarning(
          context,
          message:
              'Não é possível registrar resultados em um campeonato que ainda não foi iniciado.',
        );
        return;
      }
      if (t.status == TournamentStatus.canceled) {
        AppFeedback.showWarning(
          context,
          message: 'Este campeonato foi cancelado e não aceita mais resultados.',
        );
        return;
      }
    }

    final type = await GameResultTypeDialog.show(
      context,
      series: match,
      gameNumber: gameIndex,
      isEditing: true,
    );
    if (type == null || !context.mounted) return;

    final matchesController = MatchesController(initialSeries: match);

    switch (type) {
      case GameResultType.manual:
        final existingGame = match.gameByNumber(gameIndex);
        final result = await GameManualResultDialog.show(
          context,
          series: match,
          gameNumber: gameIndex,
          existingGame: existingGame,
        );
        if (result != null && context.mounted) {
          final error = await matchesController.updateGameResult(
            matchId: match.id,
            gameNumber: gameIndex,
            winnerTeamId: result['winnerTeamId'] as String,
            durationSeconds: result['durationSeconds'] as int,
            teamAKills: result['teamAKills'] as int,
            teamBKills: result['teamBKills'] as int,
            firstPickTeamId: result['firstPickTeamId'] as String?,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Game #$gameIndex atualizado com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.replay:
        final picked = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['dem', 'zip'],
          withData: true,
        );
        if (picked != null && picked.files.isNotEmpty && context.mounted) {
          final file = picked.files.first;
          if (file.bytes == null) {
            AppFeedback.showError(context, message: 'Arquivo inválido ou vazio.');
            return;
          }
          AppFeedback.showInfo(
            context,
            message: 'Enviando e processando replay (${file.name})...',
          );
          final error = await matchesController.uploadGameReplay(
            matchId: match.id,
            gameNumber: gameIndex,
            fileBytes: file.bytes!,
            fileName: file.name,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message:
                  'Replay processado e Game #$gameIndex atualizado com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.walkover:
        final winnerId = await GameWalkoverDialog.show(
          context,
          series: match,
          gameNumber: gameIndex,
        );
        if (winnerId != null && context.mounted) {
          final error = await matchesController.updateGameWalkover(
            matchId: match.id,
            gameNumber: gameIndex,
            winnerTeamId: winnerId,
          );
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'W.O. aplicado ao Game #$gameIndex com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.undoLastGame:
        final lastGameNum = match.games.length;
        final confirm = await AppConfirmDialog.show(
          context,
          title: 'Desfazer Último Mapa',
          message:
              'Deseja realmente remover o Game #$lastGameNum desta série? O placar será recalculado e a série será reaberta para novos envios.',
          confirmLabel: 'Desfazer Mapa',
          cancelLabel: 'Voltar',
          isDestructive: true,
        );
        if (confirm == true && context.mounted) {
          final error = await matchesController.removeLastGame(match.id);
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Game #$lastGameNum desfeito com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;

      case GameResultType.rollback:
        final confirm = await AppConfirmDialog.show(
          context,
          title: 'Reverter Série Completa',
          message:
              'ATENÇÃO: Isso apagará TODOS os mapas registrados desta série e retornará o placar para 0 x 0. Deseja prosseguir com o reset total da série?',
          confirmLabel: 'Reverter Série',
          cancelLabel: 'Cancelar',
          isDestructive: true,
        );
        if (confirm == true && context.mounted) {
          final error = await matchesController.rollbackSeries(match.id);
          if (!context.mounted) return;
          if (error == null) {
            AppFeedback.showSuccess(
              context,
              message: 'Série revertida com sucesso!',
            );
            await controller.fetchTournament(silent: true);
          } else {
            AppFeedback.showError(context, message: error);
          }
        }
        break;
    }
  }
}

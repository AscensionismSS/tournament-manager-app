import 'package:flutter/material.dart';
import '../../../../core/shared_widgets/shared_widgets.dart';
import '../../../tournaments/models/tournament_dto.dart';

/// Launcher minimalista exibido na aba de Draft da página de detalhes do torneio (SRP & Dumb UI).
/// Utiliza [AppEmptyState] sem fundo cinza/card, integrado diretamente ao tema da página.
class DraftRedirectCard extends StatelessWidget {
  final TournamentDto tournament;
  final VoidCallback onOpenDraftRoom;

  const DraftRedirectCard({
    super.key,
    required this.tournament,
    required this.onOpenDraftRoom,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.shuffle_rounded,
      title: 'DRAFT & GESTÃO DE TIMES',
      message:
          'O draft de jogadores, definição de capitães e gerenciamento das equipes acontecem em uma sala dedicada em tela cheia.',
      customAction: AppButton(
        text: 'ABRIR DRAFT & GESTÃO',
        icon: Icons.shuffle_rounded,
        size: AppButtonSize.medium,
        variant: AppButtonVariant.primary,
        onPressed: onOpenDraftRoom,
      ),
      asCard: false,
      minHeight: 320,
    );
  }
}


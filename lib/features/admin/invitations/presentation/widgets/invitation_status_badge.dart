import 'package:flutter/material.dart';
import '../../models/invitation_dto.dart';

/// Indicador visual limpo do status do convite (sem contêiner de chip)
class InvitationStatusBadge extends StatelessWidget {
  final InvitationStatus status;

  const InvitationStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(status.icon, size: 13, color: status.color),
        const SizedBox(width: 5),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: status.color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

/// Indicador visual limpo do papel do convite com tipografia direta e cor distintiva
class InvitationRoleBadge extends StatelessWidget {
  final InvitationDto invite;

  const InvitationRoleBadge({
    super.key,
    required this.invite,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      invite.roleDisplayLabel,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Oswald',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: invite.roleColor,
        letterSpacing: 0.8,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../../core/shared_widgets/shared_widgets.dart';
import '../../../../../core/theme/theme.dart';
import '../../models/invitation_dto.dart';
import 'invitation_status_badge.dart';

/// Tabela oficial desktop para gestão de convites (SRP).
/// Layout aperfeiçoado com proporções harmônicas, espaçamentos generosos entre colunas
/// e badges elegantes sem risco de sobreposição ou truncamento de texto.
class InvitationTable extends StatelessWidget {
  final List<InvitationDto> invitations;
  final String? revokingId;
  final ValueChanged<InvitationDto> onCopyCode;
  final ValueChanged<InvitationDto> onRevoke;

  const InvitationTable({
    super.key,
    required this.invitations,
    this.revokingId,
    required this.onCopyCode,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Cabeçalho da Tabela com proporções equilibradas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surfaceHighlight,
              child: const Row(
                children: [
                  // 1. Convidado (Expanded - ocupa o espaço restante)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'CONVIDADO',
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 2. Role (width: 110, Centralizado)
                  SizedBox(
                    width: 110,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'ROLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 3. Link de Convite (width: 125, Centralizado)
                  SizedBox(
                    width: 125,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'LINK DE CONVITE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 4. Status (width: 110, Centralizado)
                  SizedBox(
                    width: 110,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'STATUS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 5. Emissão / Validade (width: 155, Centralizado)
                  SizedBox(
                    width: 155,
                    child: Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Text(
                        'EMISSÃO / VALIDADE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Oswald',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // 6. Ações (width: 60, Centralizado)
                  SizedBox(
                    width: 60,
                    child: Text(
                      'AÇÕES',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Oswald',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),

            // Linhas de dados com respiro harmônico
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: invitations.length,
              separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final invite = invitations[index];
                return _buildRow(invite);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(InvitationDto invite) {
    final isRevoking = revokingId == invite.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // 1. Convidado (Expanded)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Text(
                invite.email,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // 2. Role (width: 110, Centralizado, Tipografia direta sem chip)
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: InvitationRoleBadge(invite: invite),
              ),
            ),
          ),

          // 3. Link de Convite (width: 125, Centralizado)
          SizedBox(
            width: 125,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: Tooltip(
                  message: 'Copiar link de cadastro',
                  waitDuration: const Duration(milliseconds: 300),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onCopyCode(invite),
                      borderRadius: BorderRadius.circular(6),
                      hoverColor: AppColors.dotaGold.withValues(alpha: 0.12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
                        decoration: BoxDecoration(
                          color: AppColors.dotaGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.dotaGold.withValues(alpha: 0.45),
                            width: 0.9,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link_rounded,
                              size: 14,
                              color: AppColors.dotaGold,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'COPIAR LINK',
                              style: TextStyle(
                                fontFamily: 'Oswald',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.dotaGold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. Status (width: 110, Centralizado, Ícone + Texto sem chip)
          SizedBox(
            width: 110,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Center(
                child: InvitationStatusBadge(status: invite.status),
              ),
            ),
          ),

          // 5. Emissão / Validade (width: 155, Centralizado, apenas datas e horas puras)
          SizedBox(
            width: 155,
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    invite.formattedCreatedAt,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    invite.secondLineDate,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: invite.status.color,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Ações (width: 60, Centralizado)
          SizedBox(
            width: 60,
            child: Center(
              child: invite.canBeRevoked
                  ? AppIconButton(
                      icon: Icons.cancel_outlined,
                      size: AppIconButtonSize.small,
                      variant: AppIconButtonVariant.danger,
                      tooltip: 'Revogar Convite',
                      isLoading: isRevoking,
                      onPressed: isRevoking ? null : () => onRevoke(invite),
                    )
                  : const SizedBox(
                      width: 32,
                      height: 32,
                      child: Center(
                        child: Text(
                          '—',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

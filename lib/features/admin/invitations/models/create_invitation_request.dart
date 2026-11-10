/// DTO de requisição para criação de convite (POST /api/v1/invitations).
/// Reflete com fidelidade o contrato Identity.Contracts.Invitations.CreateInvitationApiRequest.
class CreateInvitationRequest {
  final String email;
  final int targetRole;
  final int validHours; // 24, 48 ou 72

  const CreateInvitationRequest({
    required this.email,
    required this.targetRole,
    this.validHours = 24,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim(),
        'targetRole': targetRole,
        'validHours': validHours,
      };
}

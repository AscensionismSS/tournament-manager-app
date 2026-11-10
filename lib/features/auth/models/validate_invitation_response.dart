/// DTO de resposta do endpoint GET /api/v1/invitations/validate/{code}.
/// Reflete fielmente o contrato do backend para validação anônima de convite.
class ValidateInvitationResponse {
  final bool isValid;
  final String email;
  final String targetRole;
  final String? errorMessage;

  const ValidateInvitationResponse({
    required this.isValid,
    required this.email,
    required this.targetRole,
    this.errorMessage,
  });

  /// Nome amigável do papel do convite
  String get roleDisplayLabel {
    final lower = targetRole.toLowerCase();
    if (lower.contains('super')) return 'SUPERADMIN';
    if (lower.contains('admin')) return 'ADMIN TORNEIO';
    return 'JOGADOR';
  }

  factory ValidateInvitationResponse.fromJson(Map<String, dynamic> json) {
    final target = json['data'] is Map<String, dynamic>
        ? (json['data'] as Map<String, dynamic>)
        : json;

    final rawIsValid = target['isValid'] ?? target['IsValid'];
    final bool valid = rawIsValid == true || rawIsValid?.toString().toLowerCase() == 'true';

    return ValidateInvitationResponse(
      isValid: valid,
      email: (target['email'] ?? target['Email'] ?? '').toString(),
      targetRole: (target['targetRole'] ?? target['TargetRole'] ?? 'Player').toString(),
      errorMessage: target['message']?.toString() ??
          target['errorMessage']?.toString() ??
          target['error']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'email': email,
        'targetRole': targetRole,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };
}

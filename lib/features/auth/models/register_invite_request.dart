/// Payload de requisição enviado ao endpoint POST /api/v1/auth/register-invite.
/// Registro atômico com envio seguro de SteamID como String para imunidade ao arredondamento JS.
class RegisterInviteRequest {
  final String code;
  final String email;
  final String displayName;
  final String password;
  final String? steamId;

  const RegisterInviteRequest({
    required this.code,
    required this.email,
    required this.displayName,
    required this.password,
    this.steamId,
  });

  Map<String, dynamic> toJson() => {
        'code': code.trim(),
        'email': email.trim(),
        'displayName': displayName.trim(),
        'password': password,
        if (steamId != null && steamId!.trim().isNotEmpty) 'steamId': steamId!.trim(),
      };
}

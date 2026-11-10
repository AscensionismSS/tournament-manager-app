/// DTO de requisição de login.
/// Aceita 'identifier' (e-mail ou nickname de até 254 caracteres) e 'password' (mínimo 6 caracteres).
class LoginRequest {
  final String identifier;
  final String password;

  const LoginRequest({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    final cleanIdentifier = identifier.trim();
    return {
      'identifier': cleanIdentifier,
      'email': cleanIdentifier, // Compatibilidade caso o endpoint use 'email'
      'login': cleanIdentifier, // Compatibilidade caso o endpoint use 'login'
      'password': password,
    };
  }
}

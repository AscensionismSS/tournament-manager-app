import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/models/login_response.dart';

/// Serviço de armazenamento seguro de credenciais, tokens JWT e sessão do usuário.
/// Utiliza hardware-backed encryption (Keystore/EncryptedSharedPreferences no Android,
/// Keychain no iOS e DPAPI no Windows) para proteção máxima contra extração de dados.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    wOptions: WindowsOptions(),
  );

  static const String _keyToken = 'auth_jwt_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserProfile = 'auth_user_profile';

  /// Notificador reativo do perfil atual em memória para sincronização instantânea de UI
  static final ValueNotifier<LoginResponse?> profileNotifier = ValueNotifier<LoginResponse?>(null);

  /// Salva a sessão completa de autenticação (Token, Role, Dados do Usuário)
  static Future<void> saveSession(LoginResponse response) async {
    if (response.token.isNotEmpty) {
      await _storage.write(key: _keyToken, value: response.token);
    }
    if (response.refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: response.refreshToken);
    }
    await _storage.write(
      key: _keyUserProfile,
      value: jsonEncode(response.toJson()),
    );
    profileNotifier.value = response;
  }

  /// Atualiza os dados do perfil preservando o token JWT ativo
  static Future<LoginResponse> updateSessionProfile(Map<String, dynamic> userDtoJson) async {
    final currentProfile = await getUserProfile();
    final currentToken = await getToken() ?? '';

    // Se vier envelopado em 'data'
    final rawData = userDtoJson['data'] is Map<String, dynamic>
        ? (userDtoJson['data'] as Map<String, dynamic>)
        : userDtoJson;

    final updated = LoginResponse.fromJson({
      ...currentProfile?.toJson() ?? {},
      ...rawData,
      if ((rawData['token'] == null || rawData['token'].toString().isEmpty) && currentToken.isNotEmpty)
        'token': currentToken,
    });

    await _storage.write(
      key: _keyUserProfile,
      value: jsonEncode(updated.toJson()),
    );
    profileNotifier.value = updated;
    return updated;
  }

  /// Recupera o token JWT de acesso armazenado
  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  /// Recupera o perfil do usuário logado (Role, Nome, Dota Rank, Steam)
  static Future<LoginResponse?> getUserProfile() async {
    if (profileNotifier.value != null) {
      return profileNotifier.value;
    }
    final raw = await _storage.read(key: _keyUserProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final profile = LoginResponse.fromJson(decoded);
        profileNotifier.value = profile;
        return profile;
      }
    } catch (_) {}
    return null;
  }

  /// Recupera a Role do usuário autenticado ("SuperAdmin", "TournamentAdmin", "Player")
  static Future<String> getUserRole() async {
    final profile = await getUserProfile();
    return profile?.role ?? 'Player';
  }

  /// Remove todos os tokens e dados de sessão (Logout seguro)
  static Future<void> clear() async {
    profileNotifier.value = null;
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserProfile);
  }

  /// Verifica se há um token persistido e ativo
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

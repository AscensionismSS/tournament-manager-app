import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../features/auth/models/login_response.dart';
import '../navigation/app_mode.dart';

/// Serviço de armazenamento seguro de credenciais, tokens JWT e sessão do usuário.
/// Utiliza hardware-backed encryption (Keystore/EncryptedSharedPreferences no Android,
/// Keychain no iOS, DPAPI no Windows e WebCrypto/IndexedDB na Web) com hidratação O(1) em RAM.
class TokenStorage {
  TokenStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    wOptions: WindowsOptions(),
    webOptions: WebOptions(
      dbName: 'tsurus_plus_auth_vault',
      publicKey: 'tsurus_auth_key',
    ),
  );

  static const String _keyToken = 'auth_jwt_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserProfile = 'auth_user_profile';

  /// Cache em memória do token JWT ativo para acesso síncrono ultra-rápido e zero race condition
  static String? _inMemoryToken;
  static bool _isTokenHydrated = false;
  static bool _isProfileHydrated = false;
  static Future<LoginResponse?>? _pendingProfileHydration;
  static Future<String?>? _pendingTokenHydration;

  /// Notificador reativo do perfil atual em memória para sincronização instantânea de UI
  static final ValueNotifier<LoginResponse?> profileNotifier = ValueNotifier<LoginResponse?>(null);

  /// Salva a sessão completa de autenticação (Token isolado do JSON de perfil por segurança)
  static Future<void> saveSession(LoginResponse response) async {
    _inMemoryToken = response.token;
    _isTokenHydrated = true;
    _isProfileHydrated = true;
    final sanitizedProfile = response.copyWith(token: '', refreshToken: null);
    profileNotifier.value = sanitizedProfile;

    if (response.token.isNotEmpty) {
      await _storage.write(key: _keyToken, value: response.token);
    }
    if (response.refreshToken != null && response.refreshToken!.isNotEmpty) {
      await _storage.write(key: _keyRefreshToken, value: response.refreshToken);
    }

    final profileJson = sanitizedProfile.toJson()
      ..remove('token')
      ..remove('refreshToken');

    await _storage.write(
      key: _keyUserProfile,
      value: jsonEncode(profileJson),
    );
  }

  /// Atualiza os dados do perfil preservando o token JWT ativo e bloqueando sobrescrita de credenciais
  static Future<LoginResponse> updateSessionProfile(Map<String, dynamic> userDtoJson) async {
    final currentProfile = await getUserProfile();

    // Se vier envelopado em 'data'
    final rawData = userDtoJson['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(userDtoJson['data'] as Map<String, dynamic>)
        : Map<String, dynamic>.from(userDtoJson);

    // Impede que eventos externos sobrescrevam tokens de sessão
    rawData.remove('token');
    rawData.remove('refreshToken');
    if (rawData.containsKey('IsRootOwner') && !rawData.containsKey('isRootOwner')) {
      rawData['isRootOwner'] = rawData['IsRootOwner'];
    }

    final updated = LoginResponse.fromJson({
      ...currentProfile?.toJson() ?? {},
      ...rawData,
      'token': '',
    });

    final profileJson = updated.toJson()
      ..remove('token')
      ..remove('refreshToken');

    await _storage.write(
      key: _keyUserProfile,
      value: jsonEncode(profileJson),
    );
    _isProfileHydrated = true;
    profileNotifier.value = updated;
    return updated;
  }

  /// Verifica se o perfil carregado possui data de expiração vencida localmente
  static bool _isExpired(LoginResponse? profile) {
    final expiresAt = profile?.expiresAtUtc;
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().isAfter(expiresAt.toUtc());
  }

  /// Recupera o token JWT de acesso armazenado (com validação de expiração local e cache O(1) em RAM)
  static Future<String?> getToken() async {
    final profile = await getUserProfile();
    if (_isExpired(profile)) {
      await clear();
      return null;
    }

    if (_inMemoryToken != null && _inMemoryToken!.isNotEmpty) {
      return _inMemoryToken;
    }
    if (_isTokenHydrated) {
      return null;
    }

    return _pendingTokenHydration ??= _hydrateTokenFromStorage();
  }

  static Future<String?> _hydrateTokenFromStorage() async {
    try {
      final token = await _storage.read(key: _keyToken);
      if (token != null && token.isNotEmpty) {
        _inMemoryToken = token;
      }
      _isTokenHydrated = true;
      return _inMemoryToken;
    } catch (_) {
      return _inMemoryToken;
    } finally {
      _pendingTokenHydration = null;
    }
  }

  /// Recupera o perfil do usuário logado (Role, Nome, Dota Rank, Steam)
  static Future<LoginResponse?> getUserProfile() async {
    if (profileNotifier.value != null) {
      return profileNotifier.value;
    }
    if (_isProfileHydrated) {
      return null;
    }

    return _pendingProfileHydration ??= _hydrateProfileFromStorage();
  }

  static Future<LoginResponse?> _hydrateProfileFromStorage() async {
    try {
      final raw = await _storage.read(key: _keyUserProfile);
      _isProfileHydrated = true;
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final profile = LoginResponse.fromJson(decoded);
        profileNotifier.value = profile;
        return profile;
      }
    } catch (_) {
    } finally {
      _pendingProfileHydration = null;
    }
    return null;
  }

  /// Recupera a Role do usuário autenticado ("SuperAdmin", "TournamentAdmin", "Player")
  static Future<String> getUserRole() async {
    final profile = await getUserProfile();
    return profile?.role ?? 'Player';
  }

  /// Remove todos os tokens, dados de sessão e caches de navegação (Logout seguro)
  static Future<void> clear() async {
    _inMemoryToken = null;
    _isTokenHydrated = true;
    _isProfileHydrated = true;
    profileNotifier.value = null;
    AppModeState.reset();
    try {
      await _storage.delete(key: _keyToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserProfile);
    } catch (_) {}
  }

  /// Verifica se há um token persistido, íntegro e dentro do prazo de validade
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

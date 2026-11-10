import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/system_security_settings.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/signalr_service.dart';

/// Serviço singleton para gerenciar o estado global de segurança, travas e modo de manutenção.
/// Centraliza a escuta em tempo real via SignalR ("ReceiveSecuritySettingsChanged") e SSE.
class SystemSecurityService {
  static SystemSecurityService? _instance;
  static SystemSecurityService get instance =>
      _instance ??= SystemSecurityService._();

  SystemSecurityService._();

  /// Construtor visível para testes unitários
  @visibleForTesting
  factory SystemSecurityService.testable() => SystemSecurityService._();

  final ValueNotifier<SystemSecuritySettings> settingsNotifier =
      ValueNotifier<SystemSecuritySettings>(SystemSecuritySettings.initial());

  bool _isInitialized = false;

  SystemSecuritySettings get current => settingsNotifier.value;
  bool get isMaintenanceMode => current.maintenanceMode;
  bool get isResultSubmissionLocked => current.isResultSubmissionLocked;
  bool get isTournamentRegistrationLocked => current.isTournamentRegistrationLocked;
  bool get isTournamentCreationLocked => current.isTournamentCreationLocked;
  bool get isDraftPicksLocked => current.isDraftPicksLocked;
  String? get message => current.message;

  /// Inicializa ouvintes e carrega as configurações do backend
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    SignalRService.instance.addSecuritySettingsListener(_onSignalRSettingsReceived);
    await fetchSettings();
  }

  /// Trata a notificação em tempo real enviada pelo backend via SignalR
  void _onSignalRSettingsReceived(dynamic raw) {
    try {
      Map<String, dynamic>? map;
      if (raw is Map) {
        map = raw is Map<String, dynamic>
            ? raw
            : Map<String, dynamic>.from(raw);
      } else if (raw is String) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          map = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
        }
      }

      if (map != null) {
        final updated = SystemSecuritySettings.fromJson(map);
        settingsNotifier.value = updated;
        if (kDebugMode) {
          debugPrint('SystemSecurityService: Atualizado via SignalR -> '
              'maintenance=${updated.maintenanceMode}, locks=[res:${updated.lockResultSubmission}, '
              'reg:${updated.lockTournamentRegistration}, create:${updated.lockTournamentCreation}, '
              'draft:${updated.lockDraftPicks}]');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SystemSecurityService: Falha ao desserializar SignalR payload: $e');
      }
    }
  }

  /// Consulta as travas no backend (GET /api/v1/admin/security-settings)
  Future<SystemSecuritySettings> fetchSettings() async {
    try {
      final response = await ApiClient.get(
        ApiEndpoints.systemSecuritySettings,
        requiresAuth: false,
      );
      final settings = SystemSecuritySettings.fromJson(response);
      settingsNotifier.value = settings;
      return settings;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SystemSecurityService: Não foi possível obter configurações de segurança: $e');
      }
      return settingsNotifier.value;
    }
  }

  /// Atualiza as travas no backend (PUT /api/v1/admin/security-settings, exclusivo SuperAdmin)
  Future<SystemSecuritySettings> updateSettings(SystemSecuritySettings newSettings) async {
    final response = await ApiClient.put(
      ApiEndpoints.systemSecuritySettings,
      body: newSettings.toJson(),
      requiresAuth: true,
    );

    final updated = SystemSecuritySettings.fromJson(response);
    settingsNotifier.value = updated;
    return updated;
  }

  /// Atualiza manualmente o estado local (útil para testes unitários ou reações imediatas)
  void updateLocal(SystemSecuritySettings settings) {
    settingsNotifier.value = settings;
  }

  /// Libera recursos e listeners
  void dispose() {
    SignalRService.instance.removeSecuritySettingsListener(_onSignalRSettingsReceived);
    _isInitialized = false;
  }
}

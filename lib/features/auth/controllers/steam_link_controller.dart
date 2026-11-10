import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/steam_preview_dto.dart';

/// Controller para orquestrar o ciclo completo de vinculação e configuração da Steam.
/// Gerencia os estados de Preview, Link e Solicitação de Desbloqueio (SRP).
class SteamLinkController extends ChangeNotifier {
  final TextEditingController identifierController = TextEditingController();
  final FocusNode identifierFocus = FocusNode();

  final TextEditingController reasonController = TextEditingController();
  final FocusNode reasonFocus = FocusNode();

  SteamPreviewDto? _preview;
  SteamPreviewDto? get preview => _preview;

  bool _isVerifying = false;
  bool get isVerifying => _isVerifying;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isRequestingUnlock = false;
  bool get isRequestingUnlock => _isRequestingUnlock;

  bool _isUnlockRequested = false;
  bool get isUnlockRequested => _isUnlockRequested;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void resetPreview() {
    _preview = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Chamado instantaneamente quando o SignalR recebe o evento "ReceiveSteamUnlocked"
  void handleSteamUnlocked([dynamic data]) {
    identifierController.clear();
    _preview = null;
    _isUnlockRequested = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Etapa 1: Verifica o SteamID ou link de perfil via GET /api/v1/auth/preview-steam
  Future<bool> verifySteam() async {
    final text = identifierController.text.trim();
    if (text.isEmpty) {
      _errorMessage = 'Informe o SteamID64 ou o link do perfil Steam.';
      notifyListeners();
      return false;
    }

    _isVerifying = true;
    _errorMessage = null;
    _preview = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.get(
        ApiEndpoints.previewSteam(text),
        requiresAuth: true,
      );

      final result = SteamPreviewDto.fromJson(responseJson);
      _preview = result;

      if (result.isAlreadyInUse) {
        _errorMessage = result.alreadyInUseMessage ??
            'Esta conta Steam já está vinculada a outro usuário da plataforma.';
      }

      _isVerifying = false;
      notifyListeners();
      return !result.isAlreadyInUse;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isVerifying = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Erro ao verificar perfil Steam: $e';
      _isVerifying = false;
      notifyListeners();
      return false;
    }
  }

  /// Etapa 2: Salva e vincula a Steam definitivamente via POST /api/v1/auth/link-steam
  Future<bool> linkSteam() async {
    if (_preview == null || _preview!.isAlreadyInUse) {
      _errorMessage = 'Realize a verificação de um perfil válido antes de salvar.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseJson = await ApiClient.post(
        ApiEndpoints.linkSteam,
        body: {'steamId': _preview!.effectiveSteamId},
        requiresAuth: true,
      );

      // Atualiza o perfil local na sessão e notifica os ouvintes da UI
      await TokenStorage.updateSessionProfile(responseJson);

      _isSaving = false;
      _successMessage = 'Conta Steam vinculada com sucesso!';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao vincular conta Steam: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Etapa 3: Solicita a troca de conta Steam via POST /api/v1/auth/request-steam-unlock
  Future<bool> requestSteamUnlock() async {
    _isRequestingUnlock = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reason = reasonController.text.trim();
      final body = <String, dynamic>{
        'reason': reason.isNotEmpty ? reason : 'Troquei de conta',
      };

      final responseJson = await ApiClient.post(
        ApiEndpoints.requestSteamUnlock,
        body: body,
        requiresAuth: true,
      );

      _isRequestingUnlock = false;
      _isUnlockRequested = true;
      _successMessage = responseJson['message']?.toString() ??
          'Solicitação enviada ao administrador! Aguarde a liberação.';
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isRequestingUnlock = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao enviar solicitação de troca: $e';
      _isRequestingUnlock = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    identifierFocus.dispose();
    reasonController.dispose();
    reasonFocus.dispose();
    super.dispose();
  }
}

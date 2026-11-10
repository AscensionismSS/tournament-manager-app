import 'package:flutter/material.dart';
import '../../../core/navigation/app_mode.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/login_response.dart';
import '../models/register_invite_request.dart';
import '../models/steam_preview_dto.dart';
import '../models/validate_invitation_response.dart';

/// Controller reativo para orquestração da tela de registro por convite (/register?code=...).
/// Gerencia validação de token, busca anônima de perfil Steam e submissão atômica de cadastro.
class RegisterInviteController extends ChangeNotifier {
  final String code;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controladores de texto locais (todos descartados no dispose)
  final TextEditingController emailController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController steamIdentifierController = TextEditingController();

  // Estados de Validação do Convite
  bool isValidatingCode = true;
  bool isCodeValid = false;
  String? codeValidationError;
  ValidateInvitationResponse? invitationInfo;

  // Estados de Preview da Steam
  bool isVerifyingSteam = false;
  SteamPreviewDto? steamPreview;
  String? steamError;

  // Estados de Submissão de Cadastro
  bool isSubmitting = false;
  String? submitError;

  RegisterInviteController({required this.code}) {
    validateCode();
  }

  /// Valida o código do convite ao carregar a tela via GET /api/v1/invitations/validate/{code}
  Future<void> validateCode() async {
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      isValidatingCode = false;
      isCodeValid = false;
      codeValidationError = 'Nenhum código de convite foi fornecido na URL.';
      notifyListeners();
      return;
    }

    isValidatingCode = true;
    codeValidationError = null;
    notifyListeners();

    try {
      final response = await ApiClient.get(
        ApiEndpoints.invitationValidate(trimmedCode),
        requiresAuth: false,
      );

      final result = ValidateInvitationResponse.fromJson(response);
      invitationInfo = result;
      isCodeValid = result.isValid;

      if (!result.isValid) {
        codeValidationError = result.errorMessage ?? 'Este convite não é válido ou já foi utilizado.';
      }
    } on ApiException catch (e) {
      isCodeValid = false;
      codeValidationError = e.message;
    } catch (_) {
      isCodeValid = false;
      codeValidationError = 'Não foi possível validar o convite. Verifique sua conexão.';
    } finally {
      isValidatingCode = false;
      notifyListeners();
    }
  }

  /// Busca anônima do perfil Steam e rank do Dota 2 via GET /api/v1/auth/preview-steam
  Future<void> verifySteam() async {
    final identifier = steamIdentifierController.text.trim();
    if (identifier.isEmpty) {
      steamPreview = null;
      steamError = null;
      notifyListeners();
      return;
    }

    isVerifyingSteam = true;
    steamError = null;
    steamPreview = null; // Limpa estado anterior para evitar sobreposição ou dados divergentes
    notifyListeners();

    try {
      final response = await ApiClient.get(
        ApiEndpoints.previewSteam(identifier),
        requiresAuth: false,
      );

      final preview = SteamPreviewDto.fromJson(response);
      steamPreview = preview;

      if (preview.isAlreadyInUse) {
        steamError = preview.alreadyInUseMessage ?? 'Esta conta Steam já está vinculada a outro usuário.';
      }
    } on ApiException catch (e) {
      steamPreview = null;
      steamError = e.message;
    } catch (_) {
      steamPreview = null;
      steamError = 'Falha ao buscar dados na Steam. Verifique o link ou SteamID informado.';
    } finally {
      isVerifyingSteam = false;
      notifyListeners();
    }
  }

  /// Chamado sempre que o usuário altera o campo de entrada da Steam.
  /// Se havia uma Steam verificada que não corresponde mais ao texto digitado,
  /// invalida a prévia para evitar vínculo acidental de conta divergente.
  void onSteamIdentifierChanged(String value) {
    if (steamPreview != null) {
      final currentId = steamPreview!.steamId.toString().trim();
      final input = value.trim();
      if (input.isEmpty || (!input.contains(currentId) && input != currentId)) {
        steamPreview = null;
        steamError = null;
        notifyListeners();
      }
    } else if (steamError != null) {
      steamError = null;
      notifyListeners();
    }
  }

  /// Remove a Steam pré-visualizada
  void clearSteam() {
    steamPreview = null;
    steamError = null;
    steamIdentifierController.clear();
    notifyListeners();
  }

  /// Limpa erros temporários de submissão ao digitar
  void clearSubmitError() {
    if (submitError != null) {
      submitError = null;
      notifyListeners();
    }
  }

  /// Submete o registro atômico com a API via POST /api/v1/auth/register-invite
  Future<LoginResponse?> register() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }

    if (passwordController.text != confirmPasswordController.text) {
      submitError = 'As senhas não coincidem.';
      notifyListeners();
      return null;
    }

    if (steamPreview == null) {
      submitError = 'É obrigatório verificar e vincular sua conta Steam.';
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    submitError = null;
    notifyListeners();

    try {
      final request = RegisterInviteRequest(
        code: code,
        email: emailController.text.trim(),
        displayName: displayNameController.text.trim(),
        password: passwordController.text,
        steamId: steamPreview?.effectiveSteamId ?? steamPreview?.steamId,
      );

      final responseJson = await ApiClient.post(
        ApiEndpoints.authRegisterInvite,
        body: request.toJson(),
        requiresAuth: false,
      );

      final loginResponse = LoginResponse.fromJson(responseJson);

      // Salva sessão no TokenStorage seguro
      await TokenStorage.saveSession(loginResponse);

      // Sincroniza modo ativo da aplicação
      final initialMode = (loginResponse.canManageTournaments && loginResponse.prefersAdminLanding)
          ? AppMode.admin
          : AppMode.player;
      AppModeState.setMode(initialMode);

      return loginResponse;
    } on ApiException catch (e) {
      submitError = e.message;
      return null;
    } catch (e) {
      submitError = 'Ocorreu um erro ao criar a conta: $e';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    displayNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    steamIdentifierController.dispose();
    super.dispose();
  }
}

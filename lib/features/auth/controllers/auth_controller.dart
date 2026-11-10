import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';

/// Controller da Feature de Autenticação.
/// Responsável pelo ciclo de vida dos campos de texto, validações locais,
/// gerenciamento de estado da requisição e persistência de token seguro.
class AuthController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode identifierFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LoginResponse? _currentUser;
  LoginResponse? get currentUser => _currentUser;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Executa o fluxo de login chamando POST /api/v1/auth/login
  Future<bool> login() async {
    clearError();

    // Validação local de formulário antes de disparar requisição
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final request = LoginRequest(
        identifier: identifierController.text,
        password: passwordController.text,
      );

      final responseJson = await ApiClient.post(
        ApiEndpoints.authLogin,
        body: request.toJson(),
      );

      final response = LoginResponse.fromJson(responseJson);

      if (response.token.isEmpty) {
        throw const ApiException(
          statusCode: 500,
          message: 'O servidor não retornou um token válido.',
        );
      }

      // Persistência segura em Keystore / EncryptedSharedPreferences (Hardware-backed)
      await TokenStorage.saveSession(response);
      _currentUser = response;

      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Falha ao autenticar: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    identifierFocus.dispose();
    passwordFocus.dispose();
    super.dispose();
  }
}

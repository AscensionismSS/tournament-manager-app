import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../feedback/app_feedback.dart';
import '../navigation/app_router.dart';
import '../storage/token_storage.dart';

/// Exceção padronizada para erros de comunicação com a API.
/// Extrai e formata automaticamente respostas do padrão RFC 7807 (ProblemDetails).
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() => message;
}

/// Cliente HTTP desacoplado com injeção automática de Bearer Token,
/// timeout seguro e tratamento centralizado de ProblemDetails.
class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 15);
  static bool _isHandlingUnauthorized = false;

  /// Executa uma requisição POST
  static Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final headers = await _buildHeaders(requiresAuth);

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor. Verifique se o backend está rodando.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'A requisição demorou muito para responder (tempo esgotado).',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  /// Executa uma requisição PUT
  static Future<Map<String, dynamic>> put(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);

    try {
      final response = await http
          .put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor. Verifique se o backend está rodando.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'A requisição demorou muito para responder (tempo esgotado).',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  /// Executa uma requisição PATCH
  static Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);

    try {
      final response = await http
          .patch(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor. Verifique se o backend está rodando.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'A requisição demorou muito para responder (tempo esgotado).',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  /// Executa uma requisição GET
  static Future<Map<String, dynamic>> get(
    String url, {
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);

    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: headers,
          )
          .timeout(_timeout);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Tempo esgotado ao buscar dados.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  /// Executa uma requisição DELETE
  static Future<Map<String, dynamic>> delete(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    final headers = await _buildHeaders(requiresAuth);

    try {
      final response = await http
          .delete(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Tempo esgotado ao excluir dados.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Ocorreu um erro inesperado: $e',
      );
    }
  }

  /// Executa upload de arquivo via multipart/form-data
  static Future<Map<String, dynamic>> uploadMultipart(
    String url, {
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    String method = 'POST',
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    try {
      final request = http.MultipartRequest(method.toUpperCase(), Uri.parse(url));

      if (requiresAuth) {
        final token = await TokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }
      request.headers['Accept'] = 'application/json';

      if (fields != null) {
        request.fields.addAll(fields);
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return await _handleResponse(response, requiresAuth: requiresAuth);
    } on SocketException {
      throw const ApiException(
        statusCode: 0,
        message: 'Não foi possível conectar ao servidor para upload.',
      );
    } on TimeoutException {
      throw const ApiException(
        statusCode: 408,
        message: 'Tempo esgotado durante o upload do arquivo.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: -1,
        message: 'Falha durante o upload: $e',
      );
    }
  }

  static Future<Map<String, String>> _buildHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await TokenStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<Map<String, dynamic>> _handleResponse(
    http.Response response, {
    bool requiresAuth = false,
  }) async {
    Map<String, dynamic> bodyJson = {};

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          bodyJson = decoded;
        } else if (decoded is List) {
          bodyJson = {'data': decoded};
        }
      } catch (_) {
        bodyJson = {'raw': response.body};
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return bodyJson;
    }

    // Se o token expirou ou é inválido em uma rota autenticada (401 Unauthorized),
    // aciona imediatamente o fluxo automático de logout seguro e redirecionamento.
    if (response.statusCode == 401 && requiresAuth) {
      await _handleUnauthorized();
    }

    // Tratamento de ProblemDetails (RFC 7807)
    final message = _extractProblemDetailsMessage(response.statusCode, bodyJson);

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      details: bodyJson,
    );
  }

  /// Trata a expiração da sessão (401): limpa o cache, redireciona para o login e notifica o usuário
  static Future<void> _handleUnauthorized() async {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    try {
      await TokenStorage.clear();
      AppRouter.router.go('/login');

      final context = AppRouter.rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        AppFeedback.showWarning(
          context,
          title: 'SESSÃO EXPIRADA',
          message: 'Sua sessão expirou. Por favor, realize o login novamente.',
        );
      }
    } finally {
      _isHandlingUnauthorized = false;
    }
  }

  /// Extrai mensagens de erro detalhadas enviadas pelo backend em formato ProblemDetails (RFC 9457)
  static String _extractProblemDetailsMessage(
    int statusCode,
    Map<String, dynamic> body,
  ) {
    // 1. Dicionário de erros por campo específico (FluentValidation / ASP.NET Identity)
    final errors = body['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final messages = <String>[];
      for (final entry in errors.entries) {
        if (entry.value is List) {
          for (final msg in (entry.value as List)) {
            if (msg is String && msg.trim().isNotEmpty) {
              messages.add(msg.trim());
            }
          }
        } else if (entry.value is String && (entry.value as String).trim().isNotEmpty) {
          messages.add((entry.value as String).trim());
        }
      }
      if (messages.isNotEmpty) {
        return messages.first; // Exibe o primeiro erro específico de campo
      }
    }

    // 2. Mensagem amigável direta no 'detail' (padrão principal para Credenciais Inválidas)
    final detail = body['detail'] ?? body['message'] ?? body['error'];
    if (detail is String && detail.trim().isNotEmpty) {
      return detail.trim();
    }

    // 3. Título do problema
    final title = body['title'];
    if (title is String && title.trim().isNotEmpty) {
      return title.trim();
    }

    // 4. Fallbacks por código HTTP
    switch (statusCode) {
      case 400:
        return 'Dados de requisição inválidos.';
      case 401:
        return 'E-mail ou senha incorretos.';
      case 403:
        return 'Acesso não autorizado para este recurso.';
      case 404:
        return 'Serviço ou endpoint não encontrado.';
      case 500:
        return 'Falha interna no servidor. Tente novamente em instantes.';
      default:
        return 'Ocorreu um erro no servidor (HTTP $statusCode).';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../feedback/app_feedback.dart';

/// Utilitário ultra seguro para abertura de links externos com Whitelist rigorosa.
///
/// Protege o usuário contra vulnerabilidades de injeção de URL, esquemas inseguros
/// e ataques de phishing ao forçar HTTPS e permitir exclusivamente domínios
/// canônicos auditados da plataforma (Steam, OpenDota, Dotabuff, Stratz).
class SafeUrlLauncher {
  SafeUrlLauncher._();

  /// Whitelist oficial de domínios autorizados na plataforma.
  /// Qualquer link fora desta lista é sumariamente bloqueado.
  static const Set<String> _allowedDomains = {
    'steamcommunity.com',
    'www.steamcommunity.com',
    'opendota.com',
    'www.opendota.com',
    'dotabuff.com',
    'www.dotabuff.com',
    'stratz.com',
    'www.stratz.com',
  };

  /// Abre a [url] fornecida aplicando validação rigorosa de segurança.
  static Future<bool> launch(
    String url, {
    BuildContext? context,
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      if (context != null && context.mounted) {
        AppFeedback.showWarning(context, message: 'Link não informado ou inválido.');
      }
      return false;
    }

    final uri = Uri.tryParse(trimmed);

    // 1. Validação de protocolo: Apenas HTTPS permitido (proíbe http puro, javascript:, file:, etc.)
    if (uri == null || uri.scheme.toLowerCase() != 'https') {
      if (context != null && context.mounted) {
        AppFeedback.showError(
          context,
          title: 'CONEXÃO INSEGURA',
          message: 'Por segurança, apenas links seguros (HTTPS) são permitidos.',
        );
      }
      return false;
    }

    // 2. Validação de Domínio (Whitelist Anti-Phishing)
    final host = uri.host.toLowerCase();
    final isAllowed = _allowedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
    if (!isAllowed) {
      if (context != null && context.mounted) {
        AppFeedback.showError(
          context,
          title: 'ACESSO BLOQUEADO',
          message: 'O domínio "$host" não foi reconhecido como confiável pela arena.',
        );
      }
      return false;
    }

    // 3. Execução segura em aplicativo externo
    try {
      final launched = await launchUrl(uri, mode: mode);
      if (!launched && context != null && context.mounted) {
        AppFeedback.showError(context, message: 'Não foi possível abrir o navegador.');
      }
      return launched;
    } catch (_) {
      if (context != null && context.mounted) {
        AppFeedback.showError(context, message: 'Falha ao tentar abrir o navegador.');
      }
      return false;
    }
  }

  /// Atalho seguro para plataformas da arena
  static Future<bool> open(
    BuildContext context,
    String url, {
    String platformName = 'Link Externo',
  }) {
    return launch(url, context: context);
  }

  /// Monta e abre o perfil oficial da Steam do jogador garantindo a URL canônica HTTPS
  static Future<bool> openSteamProfile(
    BuildContext context,
    String steamIdOrUrl,
  ) {
    final trimmed = steamIdOrUrl.trim();

    // Se for URL, valida se é realmente da Steam oficial via HTTPS
    if (trimmed.startsWith('https://')) {
      return launch(trimmed, context: context);
    }

    // Se for o ID numérico puro (SteamID64), monta a URL canônica HTTPS garantida
    final isNumeric = RegExp(r'^\d+$').hasMatch(trimmed);
    final targetUrl = isNumeric
        ? 'https://steamcommunity.com/profiles/$trimmed'
        : 'https://steamcommunity.com/id/$trimmed';

    return launch(targetUrl, context: context);
  }
}

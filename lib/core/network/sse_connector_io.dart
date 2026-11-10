import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Implementação IO (Desktop/Mobile) de conexão Server-Sent Events (SSE).
void cleanupStaleSseConnections() {
  // No-op fora do navegador Web
}

Stream<String> connectSseStream(String url) {
  late StreamController<String> controller;
  http.Client? client;
  StreamSubscription<String>? sub;
  Timer? reconnectTimer;
  bool isActive = true;

  Future<void> connect() async {
    if (!isActive) return;
    unawaited(sub?.cancel());
    client?.close();
    client = http.Client();

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final response = await client!.send(request);
      if (response.statusCode != 200 || !isActive) {
        if (isActive) {
          reconnectTimer = Timer(const Duration(seconds: 5), connect);
        }
        return;
      }

      sub = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          final trimmed = line.trim();
          if (trimmed.startsWith('data:')) {
            final payload = trimmed.substring(5).trim();
            if (payload.isNotEmpty && !controller.isClosed) {
              controller.add(payload);
            }
          }
        },
        onError: (_) {
          if (isActive) {
            reconnectTimer = Timer(const Duration(seconds: 5), connect);
          }
        },
        onDone: () {
          if (isActive) {
            reconnectTimer = Timer(const Duration(seconds: 5), connect);
          }
        },
        cancelOnError: true,
      );
    } catch (_) {
      if (isActive) {
        reconnectTimer = Timer(const Duration(seconds: 5), connect);
      }
    }
  }

  controller = StreamController<String>(
    onListen: connect,
    onCancel: () {
      isActive = false;
      reconnectTimer?.cancel();
      unawaited(sub?.cancel());
      client?.close();
    },
  );

  return controller.stream;
}

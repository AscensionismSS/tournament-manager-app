import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('EventSource')
extension type _JSEventSource._(JSObject _) implements JSObject {
  external factory _JSEventSource(String url);
  external set onmessage(JSFunction? handler);
  external set onerror(JSFunction? handler);
  external void close();
}

@JS('MessageEvent')
extension type _JSMessageEvent._(JSObject _) implements JSObject {
  external JSAny? get data;
}

const String _globalPoolKey = '__tcActiveEventSources';

/// Fecha quaisquer conexões `EventSource` órfãs deixadas no navegador antes de um Hot Restart,
/// evitando esgotar o limite de conexões HTTP/1.1 do Chrome para `localhost:5000`.
void cleanupStaleSseConnections() {
  try {
    final existing = globalContext.getProperty<JSAny?>(_globalPoolKey.toJS);
    if (existing != null && existing.isA<JSArray>()) {
      final list = (existing as JSArray).toDart;
      for (final item in list) {
        if (item != null && item.isA<JSObject>()) {
          try {
            (item as JSObject).callMethod('close'.toJS);
          } catch (_) {}
        }
      }
    }
    globalContext.setProperty(_globalPoolKey.toJS, <JSAny?>[].toJS);
  } catch (_) {}
}

void _registerEventSource(_JSEventSource es) {
  try {
    final existing = globalContext.getProperty<JSAny?>(_globalPoolKey.toJS);
    final List<JSAny?> current =
        (existing != null && existing.isA<JSArray>())
            ? List<JSAny?>.from((existing as JSArray).toDart)
            : <JSAny?>[];
    current.add(es);
    globalContext.setProperty(_globalPoolKey.toJS, current.toJS);
  } catch (_) {}
}

void _unregisterEventSource(_JSEventSource es) {
  try {
    final existing = globalContext.getProperty<JSAny?>(_globalPoolKey.toJS);
    if (existing != null && existing.isA<JSArray>()) {
      final list = List<JSAny?>.from((existing as JSArray).toDart);
      list.remove(es);
      globalContext.setProperty(_globalPoolKey.toJS, list.toJS);
    }
  } catch (_) {}
}

/// Usa o `EventSource` nativo do navegador (idêntico ao exemplo JS `new EventSource(url)`),
/// entregando cada mensagem SSE instantaneamente e reconectando de forma nativa.
Stream<String> connectSseStream(String url) {
  late StreamController<String> controller;
  _JSEventSource? eventSource;

  void start() {
    try {
      final es = _JSEventSource(url);
      eventSource = es;
      _registerEventSource(es);

      es.onmessage = ((_JSMessageEvent event) {
        final rawData = event.data;
        if (rawData != null && rawData.isA<JSString>()) {
          final text = (rawData as JSString).toDart.trim();
          if (text.isNotEmpty && !controller.isClosed) {
            controller.add(text);
          }
        }
      }).toJS;
    } catch (_) {}
  }

  void stop() {
    final es = eventSource;
    eventSource = null;
    if (es != null) {
      try {
        es.onmessage = null;
        es.onerror = null;
        es.close();
      } catch (_) {}
      _unregisterEventSource(es);
    }
  }

  controller = StreamController<String>(
    onListen: start,
    onCancel: stop,
  );

  return controller.stream;
}

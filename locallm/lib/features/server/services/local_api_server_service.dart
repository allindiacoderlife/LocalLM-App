import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LocalApiServerService {
  HttpServer? _server;
  int _port = 8080;
  String? _apiKey;
  bool _allowNetwork = false;
  String? _lastReachableAddress;

  final StreamController<String> _logController =
      StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  bool get isRunning => _server != null;
  int get port => _server?.port ?? _port;
  String? get localUrl {
    final p = _server?.port;
    if (p == null) return null;
    final host = _allowNetwork ? (_lastReachableAddress ?? '127.0.0.1') : '127.0.0.1';
    return 'http://$host:$p';
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    _logController.add('[$timestamp] $message');
  }

  Future<String?> _getReachableAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> start({
    int port = 8080,
    String? apiKey,
    bool allowNetwork = false,
    required Future<Stream<String>> Function(String prompt, String? systemPrompt)
        onGenerateChat,
    required String Function() getCurrentModelName,
  }) async {
    if (_server != null) return;

    _port = port;
    _apiKey = (apiKey != null && apiKey.trim().isNotEmpty) ? apiKey.trim() : null;
    _allowNetwork = allowNetwork;
    _lastReachableAddress = await _getReachableAddress();

    final bindAddress =
        allowNetwork ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4;

    _server = await HttpServer.bind(bindAddress, port);
    _log('Server started on $localUrl (OpenAI compatible)');

    unawaited(_serve(_server!, onGenerateChat, getCurrentModelName));
  }

  Future<void> stop() async {
    final s = _server;
    _server = null;
    await s?.close(force: true);
    _log('Server stopped');
  }

  void updateApiKey(String? key) {
    _apiKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
    _log('API key configuration updated');
  }

  Future<void> _serve(
    HttpServer server,
    Future<Stream<String>> Function(String prompt, String? systemPrompt)
        onGenerateChat,
    String Function() getCurrentModelName,
  ) async {
    await for (final request in server) {
      unawaited(_handle(request, onGenerateChat, getCurrentModelName));
    }
  }

  Future<void> _handle(
    HttpRequest request,
    Future<Stream<String>> Function(String prompt, String? systemPrompt)
        onGenerateChat,
    String Function() getCurrentModelName,
  ) async {
    _addCors(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    final path = request.uri.path;

    // Check API Key if configured
    if (_apiKey != null) {
      final auth = request.headers.value(HttpHeaders.authorizationHeader);
      final expected = 'Bearer $_apiKey';
      if (auth == null || auth.trim() != expected) {
        _log('${request.method} $path - 401 Unauthorized');
        await _sendJson(request.response, HttpStatus.unauthorized, {
          'error': {'message': 'Invalid API Key', 'type': 'invalid_request_error'}
        });
        return;
      }
    }

    // Health check
    if (path == '/health' || path == '/') {
      _log('${request.method} $path - 200 OK');
      await _sendJson(request.response, HttpStatus.ok, {
        'status': 'healthy',
        'model': getCurrentModelName(),
      });
      return;
    }

    // Models endpoint: GET /v1/models
    if (request.method == 'GET' && path == '/v1/models') {
      _log('GET /v1/models - 200 OK');
      final currentModel = getCurrentModelName();
      await _sendJson(request.response, HttpStatus.ok, {
        'object': 'list',
        'data': [
          {
            'id': currentModel,
            'object': 'model',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'owned_by': 'locallm',
          }
        ]
      });
      return;
    }

    // Chat completions: POST /v1/chat/completions
    if (request.method == 'POST' && path == '/v1/chat/completions') {
      try {
        final bodyStr = await utf8.decoder.bind(request).join();
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        final messages = (body['messages'] as List<dynamic>? ?? []);
        final isStream = body['stream'] == true;

        String? systemPrompt;
        final promptBuffer = StringBuffer();

        for (final m in messages) {
          final role = m['role'] as String?;
          final content = m['content'] as String? ?? '';
          if (role == 'system') {
            systemPrompt = content;
          } else {
            promptBuffer.writeln('$role: $content');
          }
        }

        final prompt = promptBuffer.toString().trim();
        _log('POST /v1/chat/completions (stream=$isStream) - Generating...');

        final stream = await onGenerateChat(prompt, systemPrompt);

        if (isStream) {
          request.response.headers.contentType =
              ContentType('text', 'event-stream', charset: 'utf-8');
          request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
          request.response.headers.set(HttpHeaders.connectionHeader, 'keep-alive');

          final modelName = getCurrentModelName();
          await for (final token in stream) {
            final chunk = jsonEncode({
              'id': 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}',
              'object': 'chat.completion.chunk',
              'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
              'model': modelName,
              'choices': [
                {
                  'index': 0,
                  'delta': {'content': token},
                  'finish_reason': null,
                }
              ]
            });
            request.response.write('data: $chunk\n\n');
            await request.response.flush();
          }

          request.response.write('data: [DONE]\n\n');
          await request.response.close();
          _log('POST /v1/chat/completions - 200 Stream Finished');
        } else {
          final fullResponse = StringBuffer();
          await for (final token in stream) {
            fullResponse.write(token);
          }
          final modelName = getCurrentModelName();
          await _sendJson(request.response, HttpStatus.ok, {
            'id': 'chatcmpl-${DateTime.now().millisecondsSinceEpoch}',
            'object': 'chat.completion',
            'created': DateTime.now().millisecondsSinceEpoch ~/ 1000,
            'model': modelName,
            'choices': [
              {
                'index': 0,
                'message': {'role': 'assistant', 'content': fullResponse.toString()},
                'finish_reason': 'stop',
              }
            ]
          });
          _log('POST /v1/chat/completions - 200 OK');
        }
      } catch (e) {
        _log('Error handling chat completion: $e');
        await _sendJson(request.response, HttpStatus.internalServerError, {
          'error': {'message': e.toString(), 'type': 'internal_error'}
        });
      }
      return;
    }

    _log('${request.method} $path - 404 Not Found');
    await _sendJson(request.response, HttpStatus.notFound, {
      'error': {'message': 'Path not found: $path', 'type': 'not_found'}
    });
  }

  void _addCors(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set(
        'Access-Control-Allow-Headers', 'Content-Type, Authorization');
  }

  Future<void> _sendJson(
      HttpResponse response, int statusCode, Map<String, dynamic> data) async {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    await response.close();
  }
}

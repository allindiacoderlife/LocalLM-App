import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../chat/models/chat_message.dart';

enum CloudProvider {
  openAi,
  gemini,
  deepSeek,
  anthropic,
  openRouter,
}

class CloudInferenceService {
  final http.Client _client = http.Client();

  /// Streams token-by-token responses from the selected provider.
  Stream<String> streamChat({
    required CloudProvider provider,
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    switch (provider) {
      case CloudProvider.openAi:
      case CloudProvider.deepSeek:
      case CloudProvider.openRouter:
        yield* _streamOpenAiCompatible(
          provider: provider,
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
        break;
      case CloudProvider.gemini:
        yield* _streamGemini(
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
        break;
      case CloudProvider.anthropic:
        yield* _streamAnthropic(
          apiKey: apiKey,
          model: model,
          history: history,
          prompt: prompt,
          systemPrompt: systemPrompt,
        );
        break;
    }
  }

  Stream<String> _streamOpenAiCompatible({
    required CloudProvider provider,
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    String url = 'https://api.openai.com/v1/chat/completions';
    if (provider == CloudProvider.deepSeek) {
      url = 'https://api.deepseek.com/chat/completions';
    } else if (provider == CloudProvider.openRouter) {
      url = 'https://openrouter.ai/api/v1/chat/completions';
    }

    final messages = <Map<String, String>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    for (final msg in history) {
      messages.add({'role': msg.role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    });
    request.body = jsonEncode({
      'model': model,
      'messages': messages,
      'stream': true,
    });

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('API error (${response.statusCode}): $errorBody');
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final data = trimmed.substring(6).trim();
      if (data == '[DONE]') break;

      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        final choices = decoded['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          // Support standard content or DeepSeek reasoning_content
          final reasoning = delta?['reasoning_content'] as String?;
          final content = delta?['content'] as String?;

          if (reasoning != null && reasoning.isNotEmpty) {
            yield '<think>$reasoning';
          }
          if (content != null && content.isNotEmpty) {
            yield content;
          }
        }
      } catch (_) {}
    }
  }

  Stream<String> _streamGemini({
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    final cleanModel = model.replaceAll('models/', '');
    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$cleanModel:streamGenerateContent?alt=sse&key=$apiKey';

    final contents = <Map<String, dynamic>>[];
    for (final msg in history) {
      contents.add({
        'role': msg.role == 'assistant' ? 'model' : 'user',
        'parts': [{'text': msg.content}],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [{'text': prompt}],
    });

    final body = <String, dynamic>{'contents': contents};
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['systemInstruction'] = {
        'parts': [{'text': systemPrompt}],
      };
    }

    final request = http.Request('POST', Uri.parse(url));
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(body);

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Gemini error (${response.statusCode}): $errorBody');
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final data = trimmed.substring(6).trim();
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        final candidates = decoded['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            if (text != null) yield text;
          }
        }
      } catch (_) {}
    }
  }

  Stream<String> _streamAnthropic({
    required String apiKey,
    required String model,
    required List<ChatMessage> history,
    required String prompt,
    String? systemPrompt,
  }) async* {
    const url = 'https://api.anthropic.com/v1/messages';
    final messages = <Map<String, String>>[];
    for (final msg in history) {
      messages.add({'role': msg.role, 'content': msg.content});
    }
    messages.add({'role': 'user', 'content': prompt});

    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'max_tokens': 4096,
      'stream': true,
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    });
    request.body = jsonEncode(body);

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception('Claude error (${response.statusCode}): $errorBody');
    }

    final lines = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data: ')) continue;
      final data = trimmed.substring(6).trim();
      try {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        if (decoded['type'] == 'content_block_delta') {
          final text = decoded['delta']?['text'] as String?;
          if (text != null) yield text;
        }
      } catch (_) {}
    }
  }
}

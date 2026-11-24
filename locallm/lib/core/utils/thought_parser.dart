/// Parses streamed reasoning tags (like `<think>...</think>` from DeepSeek-R1 / Qwen)
/// separating thoughts from the final response text.
class ParsedThought {
  final String? thought;
  final String response;
  final bool isThinking;

  const ParsedThought({
    this.thought,
    required this.response,
    required this.isThinking,
  });
}

class ThoughtParser {
  ThoughtParser._();

  static ParsedThought parse(String rawText) {
    if (rawText.isEmpty) {
      return const ParsedThought(thought: null, response: '', isThinking: false);
    }

    final lower = rawText.toLowerCase();
    final thinkStart = lower.indexOf('<think>');

    if (thinkStart == -1) {
      return ParsedThought(thought: null, response: rawText, isThinking: false);
    }

    final contentAfterStart = rawText.substring(thinkStart + 7);
    final thinkEnd = contentAfterStart.toLowerCase().indexOf('</think>');

    if (thinkEnd == -1) {
      // Model is still streaming inside <think>
      return ParsedThought(
        thought: contentAfterStart.trim(),
        response: '',
        isThinking: true,
      );
    }

    // Both <think> and </think> present
    final thought = contentAfterStart.substring(0, thinkEnd).trim();
    final response = contentAfterStart.substring(thinkEnd + 8).trim();

    return ParsedThought(
      thought: thought.isEmpty ? null : thought,
      response: response,
      isThinking: false,
    );
  }
}

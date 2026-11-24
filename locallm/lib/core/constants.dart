class AppConstants {
  AppConstants._();

  // App Identity
  static const String appName = 'LocalLM';
  static const String appVersion = '1.0.0';

  // Hive Box Names
  static const String chatSessionsBox = 'chat_sessions_box';
  static const String chatMessagesBox = 'chat_messages_box';
  static const String settingsBox = 'settings_box';

  // Settings Keys
  static const String keySelectedProvider = 'selected_provider';
  static const String keyOpenAiKey = 'openai_api_key';
  static const String keyGeminiKey = 'gemini_api_key';
  static const String keyAnthropicKey = 'anthropic_api_key';
  static const String keyDeepSeekKey = 'deepseek_api_key';
  static const String keyOpenRouterKey = 'openrouter_api_key';
  static const String keyCustomBaseUrl = 'custom_base_url';
  static const String keyCustomApiKey = 'custom_api_key';

  // Selected Models
  static const String keyOpenAiModel = 'openai_model';
  static const String keyGeminiModel = 'gemini_model';
  static const String keyAnthropicModel = 'anthropic_model';
  static const String keyDeepSeekModel = 'deepseek_model';
  static const String keyOpenRouterModel = 'openrouter_model';
  static const String keyCustomModel = 'custom_model';

  // System Prompt
  static const String keySystemPrompt = 'system_prompt';
  static const String defaultSystemPrompt =
      'You are LocalLM, a knowledgeable, concise, and helpful AI assistant. Format math with LaTeX where helpful and format code inside Markdown code blocks.';
}

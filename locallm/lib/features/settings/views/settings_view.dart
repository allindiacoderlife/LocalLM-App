import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _geminiController = TextEditingController();
  final _deepSeekController = TextEditingController();
  final _openAiController = TextEditingController();
  final _claudeController = TextEditingController();
  final _openRouterController = TextEditingController();
  final _systemPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final box = Hive.box(AppConstants.settingsBox);
    _geminiController.text = box.get(AppConstants.keyGeminiKey, defaultValue: '') as String;
    _deepSeekController.text = box.get(AppConstants.keyDeepSeekKey, defaultValue: '') as String;
    _openAiController.text = box.get(AppConstants.keyOpenAiKey, defaultValue: '') as String;
    _claudeController.text = box.get(AppConstants.keyAnthropicKey, defaultValue: '') as String;
    _openRouterController.text = box.get(AppConstants.keyOpenRouterKey, defaultValue: '') as String;
    _systemPromptController.text = box.get(
      AppConstants.keySystemPrompt,
      defaultValue: AppConstants.defaultSystemPrompt,
    ) as String;
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _deepSeekController.dispose();
    _openAiController.dispose();
    _claudeController.dispose();
    _openRouterController.dispose();
    _systemPromptController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    final box = Hive.box(AppConstants.settingsBox);
    box.put(AppConstants.keyGeminiKey, _geminiController.text.trim());
    box.put(AppConstants.keyDeepSeekKey, _deepSeekController.text.trim());
    box.put(AppConstants.keyOpenAiKey, _openAiController.text.trim());
    box.put(AppConstants.keyAnthropicKey, _claudeController.text.trim());
    box.put(AppConstants.keyOpenRouterKey, _openRouterController.text.trim());
    box.put(AppConstants.keySystemPrompt, _systemPromptController.text.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & API Keys'),
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.check, color: Color(0xFF6C63FF)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('API Providers & Keys'),
          const SizedBox(height: 8),
          _buildKeyField('Google Gemini API Key', _geminiController, 'AIzaSy...'),
          _buildKeyField('DeepSeek API Key', _deepSeekController, 'sk-...'),
          _buildKeyField('OpenAI API Key', _openAiController, 'sk-...'),
          _buildKeyField('Anthropic Claude API Key', _claudeController, 'sk-ant-...'),
          _buildKeyField('OpenRouter API Key', _openRouterController, 'sk-or-...'),
          const SizedBox(height: 24),
          _buildSectionHeader('Global System Persona'),
          const SizedBox(height: 8),
          TextField(
            controller: _systemPromptController,
            maxLines: 4,
            style: const TextStyle(fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Enter global system prompt instructions...',
              filled: true,
              fillColor: const Color(0xFF1E2228),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2C323C)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2C323C)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8B84FF),
      ),
    );
  }

  Widget _buildKeyField(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFF1E2228),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C323C)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C323C)),
          ),
        ),
      ),
    );
  }
}

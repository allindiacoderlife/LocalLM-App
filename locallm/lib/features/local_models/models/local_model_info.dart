class LocalModelPreset {
  final String id;
  final String name;
  final String author;
  final String filename;
  final String downloadUrl;
  final double sizeMb;
  final String ramRequirement;
  final String description;
  final String category; // 'chat', 'image', 'uncensored', 'vision'

  const LocalModelPreset({
    required this.id,
    required this.name,
    required this.author,
    required this.filename,
    required this.downloadUrl,
    required this.sizeMb,
    required this.ramRequirement,
    required this.description,
    this.category = 'chat',
  });
}

class LocalModelPresets {
  static const List<LocalModelPreset> all = [
    // Top recommended LFM from screenshot
    LocalModelPreset(
      id: 'lfm2.5-1.2b',
      name: 'LFM2.5 1.2B Instruct (Q4_K_M)',
      author: 'Liquid AI',
      filename: 'lfm2.5-1.2b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/LiquidCloud/LFM-1.2B-Instruct-GGUF/resolve/main/LFM-1.2B-Instruct-Q4_K_M.gguf',
      sizeMb: 731.0,
      ramRequirement: '1.2 GB RAM',
      description: 'Best for chat. Ultra-efficient Liquid Neural Network architecture for on-device chat.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'smollm2-360m',
      name: 'SmolLM2 360M (8-bit High Quality)',
      author: 'HuggingFaceTB',
      filename: 'smollm2-360m-instruct-q8_0.gguf',
      downloadUrl:
          'https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q8_0.gguf',
      sizeMb: 386.0,
      ramRequirement: '1 GB RAM',
      description: 'High-precision 8-bit model for fast answers and reasoning.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen3-0.6b',
      name: 'Qwen 3 0.6B',
      author: 'Qwen',
      filename: 'qwen3-0.6b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf',
      sizeMb: 586.0,
      ramRequirement: 'LiteRT',
      description: 'Concise lightweight multilingual model optimized for mobile.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'gemma3-1b',
      name: 'Gemma 3 1B',
      author: 'Google',
      filename: 'gemma-3-1b-it-q4_0.gguf',
      downloadUrl:
          'https://huggingface.co/google/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
      sizeMb: 722.0,
      ramRequirement: 'Q4_0',
      description: 'Google state-of-the-art mobile language model.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'llama-3.2-1b',
      name: 'Llama-3.2-1B',
      author: 'Meta',
      filename: 'Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      sizeMb: 800.0,
      ramRequirement: 'Q4_K_M',
      description: "Meta's flagship on-device language model, optimized for mobile dialogue.",
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen2.5-1.5b',
      name: 'Qwen 2.5 1.5B',
      author: 'Qwen',
      filename: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      sizeMb: 1490.0,
      ramRequirement: 'LiteRT',
      description: 'High-reasoning general assistant with 1.5B parameters.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'smollm2-360m-q4',
      name: 'SmolLM2 360M (Ultra Light 4-bit)',
      author: 'HuggingFaceTB',
      filename: 'smollm2-360m-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/HuggingFaceTB/SmolLM2-360M-Instruct-GGUF/resolve/main/smollm2-360m-instruct-q4_k_m.gguf',
      sizeMb: 145.0,
      ramRequirement: '500 MB RAM',
      description: 'Super compact 145MB 4-bit model. Runs on low-RAM phones without memory pressure.',
      category: 'chat',
    ),
    // Vision models
    LocalModelPreset(
      id: 'gemma-4-e2b',
      name: 'Gemma 4 E2B',
      author: 'Google',
      filename: 'gemma-4-e2b-vision-q4_k.gguf',
      downloadUrl:
          'https://huggingface.co/google/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf',
      sizeMb: 2460.0,
      ramRequirement: 'Understands photos',
      description: 'Understands photos and visual diagrams locally on phone.',
      category: 'vision',
    ),
    LocalModelPreset(
      id: 'gemma-vision-3b',
      name: 'Gemma Vision 3.0 GB',
      author: 'Google',
      filename: 'gemma-vision-3.0gb-q4.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-11B-Vision-Instruct-GGUF/resolve/main/Llama-3.2-11B-Vision-Instruct-Q4_K_M.gguf',
      sizeMb: 3000.0,
      ramRequirement: 'No filters · 3.0 GB',
      description: 'Multi-modal vision and image perception model.',
      category: 'vision',
    ),
    // Uncensored models
    LocalModelPreset(
      id: 'dolphin-2.9-llama3-1b',
      name: 'Dolphin 2.9 Llama3 1B',
      author: 'Eric Hartford',
      filename: 'dolphin-2.9-llama3-1b.Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Llama-3.2-1B-Instruct-GGUF/resolve/main/Llama-3.2-1B-Instruct-Q4_K_M.gguf',
      sizeMb: 850.0,
      ramRequirement: '2 GB RAM',
      description: 'Uncensored assistant with zero safety filters and unfiltered reasoning.',
      category: 'uncensored',
    ),
    // Image Generation Models
    LocalModelPreset(
      id: 'sd-turbo-mobile',
      name: 'Stable Diffusion Turbo Lite',
      author: 'StabilityAI',
      filename: 'sd-turbo-mobile-q4.gguf',
      downloadUrl:
          'https://huggingface.co/stabilityai/sd-turbo/resolve/main/sd_turbo.safetensors',
      sizeMb: 1400.0,
      ramRequirement: '2.8 GB RAM',
      description: 'Single-step on-device text-to-image synthesis using ONNX/Vulkan.',
      category: 'image',
    ),
  ];
}

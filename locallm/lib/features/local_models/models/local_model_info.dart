class LocalModelPreset {
  final String id;
  final String name;
  final String author;
  final String filename;
  final String downloadUrl;
  final double sizeMb;
  final String ramRequirement;
  final String description;
  final String
      category; // 'chat', 'coding', 'reasoning', 'vision', 'uncensored', 'image'

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
  static LocalModelPreset byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => all.first);

  static const List<LocalModelPreset> all = [
    // ==========================================
    // 1. GENERAL CHAT (Low -> High Device)
    // ==========================================
    LocalModelPreset(
      id: 'smollm2-360m-q4',
      name: 'SmolLM2 360M (Ultra Light)',
      author: 'HuggingFaceTB',
      filename: 'SmolLM2-360M-Instruct-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/SmolLM2-360M-Instruct-GGUF/resolve/main/SmolLM2-360M-Instruct-Q4_K_M.gguf',
      sizeMb: 271.0,
      ramRequirement: '1 GB RAM · Low-End Phone',
      description:
          'Ultra-compact 4-bit model for budget phones and low-RAM devices.',
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
      ramRequirement: '1 GB RAM · High Quality',
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
      ramRequirement: '1.5 GB RAM · Mobile',
      description:
          'Concise lightweight multilingual model optimized for mobile.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'lfm2.5-1.2b',
      name: 'LFM2.5 1.2B Instruct (Q4_K_M)',
      author: 'Liquid AI',
      filename: 'lfm2.5-1.2b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/LiquidCloud/LFM-1.2B-Instruct-GGUF/resolve/main/LFM-1.2B-Instruct-Q4_K_M.gguf',
      sizeMb: 731.0,
      ramRequirement: '2 GB RAM · Best for Chat',
      description:
          'Best for chat. Ultra-efficient Liquid Neural Network architecture for on-device chat.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen2.5-1.5b',
      name: 'Qwen 2.5 1.5B',
      author: 'Qwen',
      filename: 'qwen2.5-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      sizeMb: 1120.0,
      ramRequirement: '3 GB RAM · Budget Device',
      description:
          'Fast everyday assistant with strong instruction following in 1.5B parameters.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen3-4b-q4',
      name: 'Qwen3 4B',
      author: 'Qwen',
      filename: 'Qwen3-4B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf',
      sizeMb: 2500.0,
      ramRequirement: '6 GB RAM · Mid-Range Phone / Laptop',
      description:
          'Balanced multilingual chat and hybrid thinking model in a compact 2.5 GB file.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen3-8b-q4',
      name: 'Qwen3 8B',
      author: 'Qwen',
      filename: 'Qwen3-8B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-8B-GGUF/resolve/main/Qwen3-8B-Q4_K_M.gguf',
      sizeMb: 5030.0,
      ramRequirement: '8–12 GB RAM · Mid-Range PC',
      description:
          'Default all-around local assistant with strong general knowledge and tool use.',
      category: 'chat',
    ),
    LocalModelPreset(
      id: 'qwen3-30b-a3b-q4',
      name: 'Qwen3 30B (MoE)',
      author: 'Qwen',
      filename: 'Qwen3-30B-A3B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen3-30B-A3B-GGUF/resolve/main/Qwen3-30B-A3B-Q4_K_M.gguf',
      sizeMb: 18600.0,
      ramRequirement: '24 GB+ VRAM/RAM · High-End PC',
      description:
          '30B Mixture-of-Experts (3B active) delivering fast, desktop-grade chat and RAG.',
      category: 'chat',
    ),

    // ==========================================
    // 2. CODING (Low -> High Device)
    // ==========================================
    LocalModelPreset(
      id: 'qwen2.5-coder-1.5b',
      name: 'Qwen 2.5 Coder 1.5B',
      author: 'Qwen',
      filename: 'qwen2.5-coder-1.5b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF/resolve/main/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf',
      sizeMb: 986.0,
      ramRequirement: '3 GB RAM · Low-End Device',
      description: 'Lightweight offline code completion and snippet generator.',
      category: 'coding',
    ),
    LocalModelPreset(
      id: 'qwen2.5-coder-7b',
      name: 'Qwen 2.5 Coder 7B',
      author: 'Qwen',
      filename: 'qwen2.5-coder-7b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF/resolve/main/qwen2.5-coder-7b-instruct-q4_k_m.gguf',
      sizeMb: 4680.0,
      ramRequirement: '8 GB RAM · Mid-Range PC',
      description:
          'Strong multi-language code generation, debugging, and refactoring.',
      category: 'coding',
    ),
    LocalModelPreset(
      id: 'qwen2.5-coder-14b',
      name: 'Qwen 2.5 Coder 14B',
      author: 'Qwen',
      filename: 'qwen2.5-coder-14b-instruct-q4_k_m.gguf',
      downloadUrl:
          'https://huggingface.co/Qwen/Qwen2.5-Coder-14B-Instruct-GGUF/resolve/main/qwen2.5-coder-14b-instruct-q4_k_m.gguf',
      sizeMb: 8990.0,
      ramRequirement: '16 GB RAM · High-Mid PC',
      description:
          'High-accuracy local coding assistant for complex multi-file logic.',
      category: 'coding',
    ),

    // ==========================================
    // 3. REASONING (Low -> High Device)
    // ==========================================
    LocalModelPreset(
      id: 'deepseek-r1-qwen-1.5b',
      name: 'DeepSeek-R1 Distill 1.5B',
      author: 'DeepSeek',
      filename: 'DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-1.5B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-1.5B-Q4_K_M.gguf',
      sizeMb: 1120.0,
      ramRequirement: '3 GB RAM · Low-End Device',
      description:
          'Step-by-step math and logic reasoning distilled for mobile devices.',
      category: 'reasoning',
    ),
    LocalModelPreset(
      id: 'deepseek-r1-qwen-7b',
      name: 'DeepSeek-R1 Distill 7B',
      author: 'DeepSeek',
      filename: 'DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF/resolve/main/DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf',
      sizeMb: 4680.0,
      ramRequirement: '8 GB RAM · Mid-Range PC',
      description:
          'Strong chain-of-thought reasoning for math, algorithms, and logic puzzles.',
      category: 'reasoning',
    ),

    // ==========================================
    // 4. VISION (Low -> High Device)
    // ==========================================
    LocalModelPreset(
      id: 'gemma-3-4b-vision',
      name: 'Gemma 3 4B Vision',
      author: 'Google',
      filename: 'gemma-3-4b-it-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/unsloth/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf',
      sizeMb: 2490.0,
      ramRequirement: '6 GB RAM · Understands Photos',
      description:
          'Multimodal model for photo understanding, OCR, and diagram reading on device.',
      category: 'vision',
    ),
    LocalModelPreset(
      id: 'gemma-3-12b-vision',
      name: 'Gemma 3 12B Vision',
      author: 'Google',
      filename: 'gemma-3-12b-it-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/unsloth/gemma-3-12b-it-GGUF/resolve/main/gemma-3-12b-it-Q4_K_M.gguf',
      sizeMb: 7300.0,
      ramRequirement: '12–16 GB RAM · High-Detail Vision',
      description:
          'High-accuracy multimodal vision and document analysis model.',
      category: 'vision',
    ),

    // ==========================================
    // 5. UNCENSORED (Low -> High Device)
    // ==========================================
    LocalModelPreset(
      id: 'dolphin-3.0-llama3.2-3b',
      name: 'Dolphin 3.0 Llama 3.2 3B',
      author: 'Eric Hartford',
      filename: 'Dolphin3.0-Llama3.2-3B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Dolphin3.0-Llama3.2-3B-GGUF/resolve/main/Dolphin3.0-Llama3.2-3B-Q4_K_M.gguf',
      sizeMb: 2020.0,
      ramRequirement: '4 GB RAM · Unfiltered',
      description:
          'Compact, steerable uncensored assistant for phones and low-RAM devices.',
      category: 'uncensored',
    ),
    LocalModelPreset(
      id: 'dolphin-3.0-llama3.1-8b',
      name: 'Dolphin 3.0 Llama 3.1 8B',
      author: 'Eric Hartford',
      filename: 'Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/bartowski/Dolphin3.0-Llama3.1-8B-GGUF/resolve/main/Dolphin3.0-Llama3.1-8B-Q4_K_M.gguf',
      sizeMb: 4920.0,
      ramRequirement: '8 GB RAM · Unfiltered',
      description:
          'Full-featured uncensored 8B model with coding, math, and general chat support.',
      category: 'uncensored',
    ),

    // ==========================================
    // 6. IMAGE GENERATION
    // ==========================================
    LocalModelPreset(
      id: 'sd-turbo-mobile',
      name: 'Stable Diffusion Turbo Lite',
      author: 'StabilityAI',
      filename: 'sd-turbo-mobile-q4.gguf',
      downloadUrl:
          'https://huggingface.co/stabilityai/sd-turbo/resolve/main/sd_turbo.safetensors',
      sizeMb: 1400.0,
      ramRequirement: '2.8 GB RAM',
      description:
          'Single-step on-device text-to-image synthesis using ONNX/Vulkan.',
      category: 'image',
    ),
    LocalModelPreset(
      id: 'sd-1.5-q4',
      name: 'Stable Diffusion 1.5 (Classic Light)',
      author: 'RunwayML',
      filename: 'v1-5-pruned-emaonly-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/city96/stable-diffusion-v1-5-gguf/resolve/main/v1-5-pruned-emaonly-Q4_K_M.gguf',
      sizeMb: 1200.0,
      ramRequirement: '4 GB VRAM / 8 GB RAM · Low-End',
      description:
          'Fast legacy model. Best for fast 512x512 generations on older laptops and mobile devices.',
      category: 'image_generation',
    ),
    LocalModelPreset(
      id: 'sdxl-turbo-q4',
      name: 'SDXL Turbo (Fast 1-Step)',
      author: 'StabilityAI',
      filename: 'sd_xl_turbo_1.0-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/city96/SDXL-Turbo-GGML/resolve/main/sd_xl_turbo_1.0-Q4_K_M.gguf',
      sizeMb: 3600.0,
      ramRequirement: '6–8 GB VRAM / VRAM · Budget GPU',
      description:
          'Ultra-fast image maker. Generates solid 512x512 images in only 1–4 steps.',
      category: 'image_generation',
    ),
    LocalModelPreset(
      id: 'sd-3.5-medium-q4',
      name: 'Stable Diffusion 3.5 Medium',
      author: 'StabilityAI',
      filename: 'sd3.5_medium-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/city96/stable-diffusion-3.5-medium-gguf/resolve/main/sd3.5_medium-Q4_K_M.gguf',
      sizeMb: 1980.0,
      ramRequirement: '6–8 GB VRAM · Mid-Range Device',
      description:
          'Compact 2B parameter version of SD 3.5. Excellent text rendering and prompt alignment.',
      category: 'image_generation',
    ),
    LocalModelPreset(
      id: 'flux1-schnell-q4',
      name: 'FLUX.1 Schnell (Fast Quality)',
      author: 'Black Forest Labs',
      filename: 'flux1-schnell-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/city96/FLUX.1-schnell-gguf/resolve/main/flux1-schnell-Q4_K_M.gguf',
      sizeMb: 6800.0,
      ramRequirement: '12–16 GB RAM/VRAM · High-Mid PC',
      description:
          'Top-tier photorealism and text in just 4 steps using a 12B model.',
      category: 'image_generation',
    ),
    LocalModelPreset(
      id: 'flux1-dev-q4',
      name: 'FLUX.1 Dev (High Detail)',
      author: 'Black Forest Labs',
      filename: 'flux1-dev-Q4_K_M.gguf',
      downloadUrl:
          'https://huggingface.co/city96/FLUX.1-dev-gguf/resolve/main/flux1-dev-Q4_K_M.gguf',
      sizeMb: 6900.0,
      ramRequirement: '16–24 GB RAM/VRAM · Enthusiast',
      description:
          'Best-in-class open image model. Hyper-detailed prompt following, hands, and text.',
      category: 'image_generation',
    ),
  ];
}

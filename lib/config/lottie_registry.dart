/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// FurSpeak AI — Central Lottie Animation Registry
///
/// ALL animation asset access MUST go through this registry.
/// Direct 'assets/animations/xxx.json' paths in screen code are FORBIDDEN.
///
/// RULES:
///   1. Only VALIDATED assets are exposed.
///   2. Broken/oversized assets are blacklisted and never returned.
///   3. Every accessor returns a safe fallback if the requested key is invalid.
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class LottieRegistry {
  LottieRegistry._();

  // ─── SAFE FALLBACK ──────────────────────────────────────────────────────
  static const String fallback = 'assets/animations/loading.json';

  // ─── BLACKLISTED ASSETS (broken, oversized, non-square) ─────────────────
  static const Set<String> _blacklisted = {
    'corgi_in_box.json', // 126KB, oversized bounding box
    'dog_4.json',        // Broken frame data
    'dog_6.json',        // Non-square aspect ratio, distorts UI
    'dog_8.json',        // Memory exhaustion risk
    'dog_9.json',        // 151KB, oversized
    'dog_10.json',       // 483KB, far exceeds 300KB Lottie budget
  };

  // ─── VALIDATED ASSET MAP ────────────────────────────────────────────────
  // Every valid asset key and its full path.
  static const Map<String, String> _registry = {
    // Core UI
    'splash':          'assets/animations/splash_dog.json',
    'loading':         'assets/animations/loading.json',
    'failed':          'assets/animations/failed.json',
    'paw_prints_bg':   'assets/animations/paw_prints_bg.json',

    // Dogs (validated)
    'dog_happy':       'assets/animations/dog_1.json',
    'dog_1':           'assets/animations/dog_1.json',
    'dog_2':           'assets/animations/dog_2.json',
    'dog_3':           'assets/animations/dog_3.json',
    'dog_5':           'assets/animations/dog_5.json',
    'dog_7':           'assets/animations/dog_7.json',

    // Characters
    'corgi_wave':      'assets/animations/corgi_wave.json',

    // Props
    'floating_ball':   'assets/animations/floating_ball.json',
    'floating_bone':   'assets/animations/floating_bone.json',

    // Onboarding
    'onboarding_1':    'assets/animations/onboarding_1.json',
    'onboarding_2':    'assets/animations/onboarding_2.json',
    'onboarding_3':    'assets/animations/onboarding_3.json',
  };

  // ─── EMOTION → ANIMATION MAP ───────────────────────────────────────────
  static const Map<String, String> _emotionMap = {
    'happy':    'dog_1',
    'relaxed':  'dog_2',
    'relax':    'dog_2',
    'alert':    'dog_3',
    'neutral':  'dog_5',
    'playful':  'dog_7',
    'surprised':'corgi_wave',
  };

  /// Get an animation path by registry key.
  /// Returns [fallback] if the key is not registered or is blacklisted.
  static String get(String key) {
    final path = _registry[key];
    if (path == null) return fallback;
    // Double-check not blacklisted (defensive)
    final filename = path.split('/').last;
    if (_blacklisted.contains(filename)) return fallback;
    return path;
  }

  /// Get the animation path for a detected emotion.
  /// Returns [fallback] if the emotion is unmapped or the asset is blacklisted.
  static String forEmotion(String? emotion) {
    final e = (emotion ?? '').toLowerCase().trim();
    final key = _emotionMap[e];
    if (key == null) return fallback;
    return get(key);
  }

  /// Returns true if the given raw filename is blacklisted.
  static bool isBlacklisted(String filename) {
    return _blacklisted.contains(filename);
  }

  /// Returns all registered keys (for debugging/auditing).
  static List<String> get allKeys => _registry.keys.toList();

  /// Returns a random validated dog animation key for the home screen shuffle.
  static String getRandomDog() {
    final dogKeys = ['dog_1', 'dog_2', 'dog_3', 'dog_5', 'dog_7'];
    final random = DateTime.now().millisecond % dogKeys.length;
    return dogKeys[random];
  }
}

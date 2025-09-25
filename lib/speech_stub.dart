typedef ResultCallback = void Function(String? text);
typedef VoidCallback = void Function();

class WebSpeechApi {
  static bool get isSupported => false;

  static void initialize({
    required ResultCallback onResult,
    required VoidCallback onEnd,
  }) {}

  static void start() {}
  static void stop() {}
}

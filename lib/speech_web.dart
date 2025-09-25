// lib/speech_web.dart
import 'dart:html';
import 'dart:js_util' as js_util;

class SpeechHelper {
  dynamic recognition; // keep dynamic because it's created via JS

  SpeechHelper() {
    // Try native SpeechRecognition
    var speechRecognition = js_util.getProperty(window, 'SpeechRecognition');

    // If not available, fallback to webkitSpeechRecognition
    speechRecognition ??= js_util.getProperty(window, 'webkitSpeechRecognition');

    if (speechRecognition != null) {
      recognition = js_util.callConstructor(speechRecognition, []);
    }
  }

  void start(Function(String) onResult, {Function(String)? onError}) {
    if (recognition == null) {
      onError?.call("Speech recognition not supported in this browser.");
      return;
    }

    // Configure recognition
    js_util.setProperty(recognition, 'lang', 'en-US');
    js_util.setProperty(recognition, 'continuous', false);
    js_util.setProperty(recognition, 'interimResults', false);

    // Handle results
    js_util.setProperty(recognition, 'onresult', (event) {
      try {
        final results = js_util.getProperty(event, 'results');
        if (results != null) {
          final firstResult = js_util.getProperty(results, '0');
          final firstAlt = js_util.getProperty(firstResult, '0');
          final transcript = js_util.getProperty(firstAlt, 'transcript');
          onResult(transcript.toString());
        }
      } catch (e) {
        onError?.call("Result parse error: $e");
      }
    });

    // Handle errors safely
    js_util.setProperty(recognition, 'onerror', (event) {
      final err = js_util.getProperty(event, 'error');
      onError?.call(err?.toString() ?? "Unknown error");
    });

    // Start recognition
    js_util.callMethod(recognition, 'start', []);
  }

  void stop() {
    if (recognition != null) {
      js_util.callMethod(recognition, 'stop', []);
    }
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ JS interop
import 'package:js/js.dart';
import 'package:web/web.dart' as web;

@JS('initSpeechRecognition')
external void initSpeechRecognition(Function callback);

@JS('startListening')
external void startListening();

@JS('stopListening')
external void stopListening();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'I-TYPEKOTO — Web TTS + STT',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
      ),
      home: const TtsHomePage(),
    );
  }
}

class TtsHomePage extends StatefulWidget {
  const TtsHomePage({super.key});

  @override
  State<TtsHomePage> createState() => _TtsHomePageState();
}

class _TtsHomePageState extends State<TtsHomePage> {
  final FlutterTts _tts = FlutterTts();
  final TextEditingController _controller = TextEditingController(
    text: 'Welcome to I-TYPEKOTO. Type text here and press Speak!',
  );

  // TTS settings
  List<String> _languages = [];
  String? _selectedLanguage;
  double _rate = 0.9;
  double _pitch = 1.0;
  bool _isSpeaking = false;
  bool _isInitializing = true;

  // STT state
  bool _isListening = false;
  String _liveText = ""; // Stores live recognized text progressively

  @override
  void initState() {
    super.initState();
    _initTts();

    // Initialize JS STT with progressive live preview
    initSpeechRecognition(allowInterop((String result, bool isError) {
      if (isError) {
        debugPrint("⚠️ STT Error: $result");
      } else {
        // Append recognized text progressively
        setState(() {
          _liveText = result; // result contains the current partial text
          _controller.text = _liveText;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      }
    }));
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(_rate);
      await _tts.setPitch(_pitch);

      try {
        final langs = await _tts.getLanguages;
        if (langs != null) _languages = List<String>.from(langs);
      } catch (_) {}

      _tts.setStartHandler(() => setState(() => _isSpeaking = true));
      _tts.setCompletionHandler(() => setState(() => _isSpeaking = false));
      _tts.setErrorHandler((msg) {
        if (kDebugMode) print("TTS error: $msg");
        setState(() => _isSpeaking = false);
      });
    } catch (e) {
      if (kDebugMode) print("Error initializing TTS: $e");
    }

    setState(() {
      _isInitializing = false;
      if (_languages.isNotEmpty) _selectedLanguage ??= _languages.first;
    });
  }

  Future<void> _speak() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (_selectedLanguage != null) {
      try {
        await _tts.setLanguage(_selectedLanguage!);
      } catch (_) {}
    }

    await _tts.setSpeechRate(_rate);
    await _tts.setPitch(_pitch);
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  void _startListening() {
    startListening();
    setState(() => _isListening = true);
  }

  void _stopListening() {
    stopListening();
    setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    super.dispose();
  }

  // =================== Reusable Widgets ===================
  Widget _buildSlider(
          String label, double value, double min, double max, ValueChanged<double> onChanged) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: 10,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ],
      );

  Widget _buildButton(
          {required String label,
          required IconData icon,
          required VoidCallback? onPressed,
          Color? color}) =>
      ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

  // ========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 30),

                    // Title
                    Text(
                      "I-TYPEKOTO",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Web Text-to-Speech + Speech-to-Text",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Main Card
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Text Field (Live Preview)
                                TextField(
                                  controller: _controller,
                                  maxLines: 5,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: const InputDecoration(
                                    labelText: "Enter text here",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Language Selector
                                if (_languages.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Select Language',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _selectedLanguage,
                                    items: _languages
                                        .map((l) => DropdownMenuItem(
                                              value: l,
                                              child: Text(l),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedLanguage = v),
                                  ),
                                const SizedBox(height: 20),

                                // Sliders
                                _buildSlider("Rate", _rate, 0.1, 1.5,
                                    (v) => setState(() => _rate = v)),
                                const SizedBox(height: 12),
                                _buildSlider("Pitch", _pitch, 0.5, 2.0,
                                    (v) => setState(() => _pitch = v)),
                                const SizedBox(height: 25),

                                // Buttons
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    _buildButton(
                                      label: "Speak",
                                      icon: Icons.volume_up,
                                      onPressed: _isInitializing || _isSpeaking
                                          ? null
                                          : _speak,
                                    ),
                                    _buildButton(
                                      label: "Stop",
                                      icon: Icons.stop,
                                      color: Colors.red,
                                      onPressed: _isSpeaking ? _stop : null,
                                    ),
                                    _buildButton(
                                      label: "Copy",
                                      icon: Icons.copy,
                                      onPressed: () {
                                        Clipboard.setData(
                                            ClipboardData(text: _controller.text));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text("Copied to clipboard")),
                                        );
                                      },
                                    ),
                                    _buildButton(
                                      label: "Voice Input",
                                      icon: Icons.mic,
                                      color: Colors.green,
                                      onPressed: _isListening ? null : _startListening,
                                    ),
                                    _buildButton(
                                      label: "Stop Voice",
                                      icon: Icons.mic_off,
                                      color: Colors.orange,
                                      onPressed: _isListening ? _stopListening : null,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Footer
                    Text(
                      "© 2025 I-TYPEKOTO. All rights reserved.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

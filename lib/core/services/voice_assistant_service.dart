import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum VoiceState { idle, listening, processing, speaking }

class VoiceAssistantService {
  static final VoiceAssistantService instance = VoiceAssistantService._init();

  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;

  bool _isTtsInitialized = false;
  bool _isSttInitialized = false;
  bool _speechEnabled = false;
  VoiceState _state = VoiceState.idle;

  // Configuration
  bool voiceAlertsEnabled = true;
  double speechRate = 0.5;
  double pitch = 1.0;
  double volume = 1.0;

  VoiceState get state => _state;
  bool get isListening => _state == VoiceState.listening;
  bool get isSpeaking => _state == VoiceState.speaking;
  bool get speechEnabled => _speechEnabled;

  VoiceAssistantService._init() {
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();
    _initTts();
  }

  Future<void> _initTts() async {
    if (_isTtsInitialized) return;

    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(speechRate);
      await _flutterTts.setVolume(volume);
      await _flutterTts.setPitch(pitch);

      _flutterTts.setStartHandler(() {
        _state = VoiceState.speaking;
      });

      _flutterTts.setCompletionHandler(() {
        _state = VoiceState.idle;
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        _state = VoiceState.idle;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
    }
  }

  Future<bool> initSpeech() async {
    if (_isSttInitialized) return _speechEnabled;

    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            if (_state == VoiceState.listening) {
              _state = VoiceState.idle;
            }
          }
        },
        onError: (error) {
          debugPrint('STT Error: ${error.errorMsg}');
          _state = VoiceState.idle;
        },
      );
      _isSttInitialized = true;
    } catch (e) {
      debugPrint('Error initializing STT: $e');
      _speechEnabled = false;
    }
    return _speechEnabled;
  }

  /// Speak text aloud through offline TTS engine
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      await _initTts();
    }

    try {
      await stopListening();
      _state = VoiceState.speaking;
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking: $e');
      _state = VoiceState.idle;
    }
  }

  /// Stop any ongoing speech
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      _state = VoiceState.idle;
    } catch (e) {
      debugPrint('Error stopping TTS: $e');
    }
  }

  /// Start listening for voice input
  Future<void> startListening({
    required Function(String words) onResult,
    Function(VoiceState state)? onStateChange,
  }) async {
    if (isSpeaking) {
      await stopSpeaking();
    }

    final available = await initSpeech();
    if (!available) {
      debugPrint('Speech recognition not available on this platform/device.');
      return;
    }

    try {
      _state = VoiceState.listening;
      onStateChange?.call(_state);

      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult) {
            _state = VoiceState.processing;
            onStateChange?.call(_state);
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenFor: const Duration(seconds: 25),
          pauseFor: const Duration(seconds: 3),
          localeId: "en_US",
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      debugPrint('Error starting listening: $e');
      _state = VoiceState.idle;
      onStateChange?.call(_state);
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
      _state = VoiceState.idle;
    } catch (e) {
      debugPrint('Error stopping STT: $e');
    }
  }

  /// Speak automated alert message if voice alerts are enabled
  Future<void> speakAlert(String message) async {
    if (!voiceAlertsEnabled) return;
    await speak(message);
  }

  /// Update speech rate for TTS engine
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }
}

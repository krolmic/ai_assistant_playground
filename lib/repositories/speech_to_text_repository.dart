import 'package:flutter_fimber/flutter_fimber.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Repository for managing speech to text functionality
class SpeechToTextRepository {
  SpeechToTextRepository() : _speechToText = SpeechToText();

  final SpeechToText _speechToText;

  /// Initialize the speech to text service
  /// Returns true if initialization was successful
  Future<bool> init() async {
    final available = await _speechToText.initialize(
      onStatus: (status) => Fimber.v('Speech status: $status'),
      onError: (error) => Fimber.e('Speech error: $error'),
    );
    return available;
  }

  /// Start listening for speech input
  /// [onResult] callback is called when speech is recognized
  Future<void> startListening({
    required void Function(SpeechRecognitionResult) onResult,
    void Function()? onListening,
  }) async {
    if (!_speechToText.isAvailable) {
      Fimber.e('Speech to text is not available');
      return;
    }

    await _speechToText.listen(
      onResult: onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    onListening?.call();
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Check if speech to text is available
  bool get isAvailable => _speechToText.isAvailable;

  /// Dispose of resources
  void dispose() {
    // SpeechToText doesn't have a dispose method, but we can stop listening
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }
}

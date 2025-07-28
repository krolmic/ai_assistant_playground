import 'package:ai_assistant_1/repositories/repositories.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

part 'voice_assistant_state.dart';

class VoiceAssistantCubit extends Cubit<VoiceAssistantState> {
  VoiceAssistantCubit({
    required SpeechToTextRepository speechToTextRepository,
    required TextResponsesRepository textResponsesRepository,
  })  : _speechToTextRepository = speechToTextRepository,
        _textResponsesRepository = textResponsesRepository,
        super(const VoiceAssistantState()) {
    _initialize();
  }

  final SpeechToTextRepository _speechToTextRepository;
  final TextResponsesRepository _textResponsesRepository;
  String _currentSpeechText = '';

  Future<void> _initialize() async {
    await _initializeSpeechToText();
    await _initializeChatSession();
  }

  Future<void> _initializeSpeechToText() async {
    final initialized = await _speechToTextRepository.init();
    if (!initialized) {
      print('Failed to initialize speech to text');
    }
  }

  Future<void> _initializeChatSession() async {
    try {
      final sessionId = await _textResponsesRepository.initChatSession(
        modelType: 'gemini',
        systemInstructions: 'You are a helpful AI assistant.',
        temperature: 0.8,
      );

      emit(state.copyWith(sessionId: sessionId));
    } catch (e) {
      print('Failed to initialize chat session: $e');
    }
  }

  Future<void> startListening() async {
    if (state.listeningToSpeechStatus == ListeningToSpeechStatus.listening) {
      return;
    }

    _currentSpeechText = '';

    emit(
      state.copyWith(
        listeningToSpeechStatus: ListeningToSpeechStatus.listening,
      ),
    );

    await _speechToTextRepository.startListening(
      onResult: _onSpeechResult,
    );
  }

  Future<void> stopListening() async {
    if (state.listeningToSpeechStatus == ListeningToSpeechStatus.idle) {
      return;
    }

    await _speechToTextRepository.stopListening();

    emit(
      state.copyWith(
        listeningToSpeechStatus: ListeningToSpeechStatus.idle,
        lastRequestText: _currentSpeechText,
      ),
    );

    if (_currentSpeechText.isNotEmpty && state.sessionId.isNotEmpty) {
      await _getResponseText(_currentSpeechText);
    }
  }

  Future<void> _getResponseText(String message) async {
    try {
      emit(state.copyWith(responseStatus: ResponseStatus.loading));

      final response = await _textResponsesRepository.getAnswer(
        sessionId: state.sessionId,
        modelType: 'gemini',
        messages: [message],
        systemInstructions: 'You are a helpful AI assistant.',
      );

      emit(
        state.copyWith(
          responseStatus: ResponseStatus.success,
          lastResponseText: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          responseStatus: ResponseStatus.error,
          lastResponseText: 'Failed to get response: $e',
        ),
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _currentSpeechText = result.recognizedWords;

    // If the result is final, stop listening automatically
    if (result.finalResult) {
      stopListening();
    }
  }

  @override
  Future<void> close() {
    _speechToTextRepository.dispose();
    return super.close();
  }
}

import 'package:ai_assistant_1/repositories/repositories.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_fimber/flutter_fimber.dart';
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

  Future<void> _initialize() async {
    await _initializeSpeechToText();
    await _initializeChatSession();
  }

  Future<void> _initializeSpeechToText() async {
    try {
      final initialized = await _speechToTextRepository.init();
      if (!initialized) {
        Fimber.e('Failed to initialize speech to text');
      }
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to initialize speech to text: $e',
        ex: e,
        stacktrace: stackTrace,
      );
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
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to initialize chat session: $e',
        ex: e,
        stacktrace: stackTrace,
      );
    }
  }

  Future<void> startListening() async {
    if (state.listeningToSpeechStatus == ListeningToSpeechStatus.listening) {
      return;
    }

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
      ),
    );

    if (state.lastRequestText.isNotEmpty && state.sessionId.isNotEmpty) {
      await _getResponseText(state.lastRequestText);
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
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to get response: $e',
        ex: e,
        stacktrace: stackTrace,
      );
      emit(
        state.copyWith(
          responseStatus: ResponseStatus.error,
          lastResponseText: 'Failed to get response: $e',
        ),
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    emit(
      state.copyWith(
        lastRequestText: result.recognizedWords,
      ),
    );

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

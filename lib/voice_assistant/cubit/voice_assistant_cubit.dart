import 'package:ai_assistant_1/repositories/repositories.dart';
import 'package:ai_assistant_1/voice_assistant/models/models.dart';
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

    if (state.currentSpeechText.isNotEmpty && state.sessionId.isNotEmpty) {
      final userMessage = Message(
        text: state.currentSpeechText,
        author: MessageAuthor.user,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          messages: [...state.messages, userMessage],
          currentSpeechText: '',
        ),
      );

      await _getResponseText(userMessage.text);
    }
  }

  Future<void> _getResponseText(String message) async {
    try {
      emit(state.copyWith(responseStatus: ResponseStatus.loading));

      final response = await _textResponsesRepository.getAnswer(
        sessionId: state.sessionId,
        messages: [message],
        systemInstructions: 'You are a helpful AI assistant.',
      );

      final assistantMessage = Message(
        text: response,
        author: MessageAuthor.assistant,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          responseStatus: ResponseStatus.success,
          messages: [...state.messages, assistantMessage],
        ),
      );
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to get response: $e',
        ex: e,
        stacktrace: stackTrace,
      );

      final errorMessage = Message(
        text: 'Failed to get response: $e',
        author: MessageAuthor.assistant,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          responseStatus: ResponseStatus.error,
          messages: [...state.messages, errorMessage],
        ),
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    emit(
      state.copyWith(
        currentSpeechText: result.recognizedWords,
      ),
    );

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

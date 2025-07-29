part of 'voice_assistant_cubit.dart';

enum ListeningToSpeechStatus { idle, listening }

enum ResponseStatus { initial, loading, success, error }

class VoiceAssistantState extends Equatable {
  const VoiceAssistantState({
    this.listeningToSpeechStatus = ListeningToSpeechStatus.idle,
    this.currentSpeechText = '',
    this.responseStatus = ResponseStatus.initial,
    this.messages = const [],
    this.sessionId = '',
  });

  final ListeningToSpeechStatus listeningToSpeechStatus;
  final String currentSpeechText;
  final ResponseStatus responseStatus;
  final List<Message> messages;
  final String sessionId;

  VoiceAssistantState copyWith({
    ListeningToSpeechStatus? listeningToSpeechStatus,
    String? currentSpeechText,
    ResponseStatus? responseStatus,
    List<Message>? messages,
    String? sessionId,
  }) {
    return VoiceAssistantState(
      listeningToSpeechStatus:
          listeningToSpeechStatus ?? this.listeningToSpeechStatus,
      currentSpeechText: currentSpeechText ?? this.currentSpeechText,
      responseStatus: responseStatus ?? this.responseStatus,
      messages: messages ?? this.messages,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object> get props => [
        listeningToSpeechStatus,
        currentSpeechText,
        responseStatus,
        messages,
        sessionId,
      ];
}

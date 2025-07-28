part of 'voice_assistant_cubit.dart';

enum ListeningToSpeechStatus { idle, listening }

enum ResponseStatus { initial, loading, success, error }

class VoiceAssistantState extends Equatable {
  const VoiceAssistantState({
    this.listeningToSpeechStatus = ListeningToSpeechStatus.idle,
    this.lastRequestText = '',
    this.responseStatus = ResponseStatus.initial,
    this.lastResponseText = '',
    this.sessionId = '',
  });

  final ListeningToSpeechStatus listeningToSpeechStatus;
  final String lastRequestText;
  final ResponseStatus responseStatus;
  final String lastResponseText;
  final String sessionId;

  VoiceAssistantState copyWith({
    ListeningToSpeechStatus? listeningToSpeechStatus,
    String? lastRequestText,
    ResponseStatus? responseStatus,
    String? lastResponseText,
    String? sessionId,
  }) {
    return VoiceAssistantState(
      listeningToSpeechStatus:
          listeningToSpeechStatus ?? this.listeningToSpeechStatus,
      lastRequestText: lastRequestText ?? this.lastRequestText,
      responseStatus: responseStatus ?? this.responseStatus,
      lastResponseText: lastResponseText ?? this.lastResponseText,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  @override
  List<Object> get props => [
        listeningToSpeechStatus,
        lastRequestText,
        responseStatus,
        lastResponseText,
        sessionId,
      ];
}

import 'package:ai_assistant_1/apis/apis.dart';

class TextResponsesRepository {
  TextResponsesRepository({
    required TextResponsesApi api,
  }) : _api = api;

  final TextResponsesApi _api;

  Future<String> initChatSession({
    required String systemInstructions,
    required double temperature,
  }) async {
    return _api.initChatSession(
      systemInstructions: systemInstructions,
      temperature: temperature,
    );
  }

  Future<String> getAnswer({
    required String sessionId,
    required List<String> messages,
    required String systemInstructions,
  }) async {
    return _api.getAnswer(
      sessionId: sessionId,
      messages: messages,
      systemInstructions: systemInstructions,
    );
  }

  Future<void> deleteSession({
    required String sessionId,
  }) async {
    return _api.deleteSession(sessionId: sessionId);
  }
}

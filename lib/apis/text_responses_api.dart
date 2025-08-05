abstract class TextResponsesApi {
  Future<String> initChatSession({
    required String systemInstructions,
    required double temperature,
  });

  Future<String> getAnswer({
    required String sessionId,
    required List<String> messages,
    required String systemInstructions,
  });

  Future<void> deleteSession({
    required String sessionId,
  });
}

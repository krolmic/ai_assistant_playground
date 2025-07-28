import 'package:cloud_functions/cloud_functions.dart';

class TextResponsesRepository {
  TextResponsesRepository({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> initChatSession({
    required String modelType,
    required String systemInstructions,
    required double temperature,
  }) async {
    final callable = _functions.httpsCallable('initChatFlow');
    final result = await callable.call<Map<String, dynamic>>({
      'modelType': modelType,
      'systemInstructions': systemInstructions,
      'temperature': temperature,
    });

    final sessionId = result.data['sessionId'] as String?;
    if (sessionId == null) {
      throw Exception('Session ID not returned from initChatFlow');
    }

    return sessionId;
  }

  Future<String> getAnswer({
    required String sessionId,
    required String modelType,
    required List<String> messages,
    required String systemInstructions,
  }) async {
    final callable = _functions.httpsCallable('sendMessages');
    final result = await callable.call<Map<String, dynamic>>({
      'sessionId': sessionId,
      'modelType': modelType,
      'messages': messages,
      'systemInstructions': systemInstructions,
    });

    final response = result.data['response'] as String?;
    if (response == null) {
      throw Exception('Response not returned from sendMessages');
    }

    return response;
  }

  Future<void> deleteSession({
    required String sessionId,
  }) async {
    final callable = _functions.httpsCallable('deleteSessionFlow');
    await callable.call<void>({
      'sessionId': sessionId,
    });
  }
}

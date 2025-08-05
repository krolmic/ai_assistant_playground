import 'package:cloud_functions/cloud_functions.dart';

import 'text_responses_api.dart';

class GenkitGrokTextResponsesApi extends TextResponsesApi {
  GenkitGrokTextResponsesApi({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  @override
  Future<String> initChatSession({
    required String systemInstructions,
    required double temperature,
  }) async {
    final callable = _functions.httpsCallable('initChat');
    final result = await callable.call<Map<String, dynamic>>({
      'modelType': 'grok',
      'systemInstructions': systemInstructions,
      'temperature': temperature,
    });

    final sessionId = result.data['sessionId'] as String?;
    if (sessionId == null) {
      throw Exception('Session ID not returned from Grok initChatFlow');
    }

    return sessionId;
  }

  @override
  Future<String> getAnswer({
    required String sessionId,
    required List<String> messages,
    required String systemInstructions,
  }) async {
    final callable = _functions.httpsCallable('sendMessages');
    final result = await callable.call<Map<String, dynamic>>({
      'sessionId': sessionId,
      'modelType': 'grok',
      'messages': messages,
      'systemInstructions': systemInstructions,
    });

    final response = result.data['response'] as String?;
    if (response == null) {
      throw Exception('Response not returned from Grok sendMessages');
    }

    return response;
  }

  @override
  Future<void> deleteSession({
    required String sessionId,
  }) async {
    final callable = _functions.httpsCallable('deleteChatSession');
    await callable.call<void>({
      'sessionId': sessionId,
    });
  }
}

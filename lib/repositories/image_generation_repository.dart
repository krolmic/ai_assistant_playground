import 'package:cloud_functions/cloud_functions.dart';

class ImageGenerationRepository {
  ImageGenerationRepository({
    FirebaseFunctions? functions,
  }) : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<String> generateImage({
    required String prompt,
  }) async {
    final callable = _functions.httpsCallable('generateImageFromPrompt');
    final result = await callable.call({
      'modelType': 'dallE',
      'prompt': prompt,
    });

    final data = result.data as Map<String, dynamic>;
    final base64String = data['imageBase64'] as String;

    // Remove data URL prefix if present (e.g., "data:image/png;base64,")
    if (base64String.contains(',')) {
      return base64String.split(',').last;
    }

    return base64String;
  }
}

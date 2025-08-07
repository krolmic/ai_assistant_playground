import 'package:ai_assistant_1/apis/apis.dart';

class ImageGenerationRepository {
  ImageGenerationRepository({
    required ImageGenerationApi api,
  }) : _api = api;

  final ImageGenerationApi _api;

  Future<String> generateImage({
    required String prompt,
  }) async {
    return _api.generateImage(prompt: prompt);
  }
}

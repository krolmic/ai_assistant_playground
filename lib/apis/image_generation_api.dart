abstract class ImageGenerationApi {
  Future<String> generateImage({
    required String prompt,
  });
}

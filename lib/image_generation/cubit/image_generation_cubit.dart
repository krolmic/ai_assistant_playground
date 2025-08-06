import 'package:ai_assistant_1/image_generation/models/models.dart';
import 'package:ai_assistant_1/repositories/image_generation_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_fimber/flutter_fimber.dart';

part 'image_generation_state.dart';

class ImageGenerationCubit extends Cubit<ImageGenerationState> {
  ImageGenerationCubit({
    required ImageGenerationRepository imageGenerationRepository,
  })  : _imageGenerationRepository = imageGenerationRepository,
        super(const ImageGenerationState());

  final ImageGenerationRepository _imageGenerationRepository;

  void updatePrompt(String prompt) {
    emit(state.copyWith(currentPrompt: prompt));
  }

  Future<void> generateImage() async {
    if (state.currentPrompt.trim().isEmpty) {
      return;
    }

    final userMessage = ImageMessage(
      text: state.currentPrompt.trim(),
      author: MessageAuthor.user,
      timestamp: DateTime.now(),
    );

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage],
        generationStatus: ImageGenerationStatus.loading,
        currentPrompt: '',
      ),
    );

    try {
      final imageBase64 = await _imageGenerationRepository.generateImage(
        prompt: userMessage.text,
      );

      final assistantMessage = ImageMessage(
        text: 'Generated image for: "${userMessage.text}"',
        author: MessageAuthor.assistant,
        timestamp: DateTime.now(),
        imageBase64: imageBase64,
      );

      emit(
        state.copyWith(
          generationStatus: ImageGenerationStatus.success,
          messages: [...state.messages, assistantMessage],
        ),
      );
    } catch (e, stackTrace) {
      Fimber.e(
        'Failed to generate image: $e',
        ex: e,
        stacktrace: stackTrace,
      );

      final errorMessage = ImageMessage(
        text: 'Failed to generate image: $e',
        author: MessageAuthor.assistant,
        timestamp: DateTime.now(),
      );

      emit(
        state.copyWith(
          generationStatus: ImageGenerationStatus.error,
          messages: [...state.messages, errorMessage],
        ),
      );
    }
  }

  void clearMessages() {
    emit(state.copyWith(messages: []));
  }
}

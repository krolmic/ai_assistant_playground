part of 'image_generation_cubit.dart';

enum ImageGenerationStatus { initial, loading, success, error }

class ImageGenerationState extends Equatable {
  const ImageGenerationState({
    this.currentPrompt = '',
    this.generationStatus = ImageGenerationStatus.initial,
    this.messages = const [],
  });

  final String currentPrompt;
  final ImageGenerationStatus generationStatus;
  final List<ImageMessage> messages;

  ImageGenerationState copyWith({
    String? currentPrompt,
    ImageGenerationStatus? generationStatus,
    List<ImageMessage>? messages,
  }) {
    return ImageGenerationState(
      currentPrompt: currentPrompt ?? this.currentPrompt,
      generationStatus: generationStatus ?? this.generationStatus,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object> get props => [
        currentPrompt,
        generationStatus,
        messages,
      ];
}

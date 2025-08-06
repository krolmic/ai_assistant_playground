import 'package:equatable/equatable.dart';

enum MessageAuthor { user, assistant }

class ImageMessage extends Equatable {
  const ImageMessage({
    required this.text,
    required this.author,
    required this.timestamp,
    this.imageBase64,
  });

  final String text;
  final MessageAuthor author;
  final DateTime timestamp;
  final String? imageBase64;

  @override
  List<Object?> get props => [text, author, timestamp, imageBase64];
}

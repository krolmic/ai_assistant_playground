import 'package:equatable/equatable.dart';

enum MessageAuthor { user, assistant }

class Message extends Equatable {
  const Message({
    required this.text,
    required this.author,
    required this.timestamp,
  });

  final String text;
  final MessageAuthor author;
  final DateTime timestamp;

  @override
  List<Object> get props => [text, author, timestamp];
}

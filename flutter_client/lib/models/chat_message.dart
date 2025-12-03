class ChatMessageModel {
  ChatMessageModel({
    required this.id,
    required this.message,
    required this.isUser,
    this.templateId,
    this.timestamp,
    this.metadata,
  });

  final String id;
  final String message;
  final bool isUser;
  final String? templateId;
  final DateTime? timestamp;
  final Map<String, dynamic>? metadata;
}

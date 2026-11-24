class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant' or 'system'
  final String content;
  final DateTime timestamp;
  final String? thought;
  final String? attachmentName;
  final String? attachmentType; // 'pdf', 'image', 'text'
  final double? tokensPerSec;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.thought,
    this.attachmentName,
    this.attachmentType,
    this.tokensPerSec,
  });

  ChatMessage copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? timestamp,
    String? thought,
    String? attachmentName,
    String? attachmentType,
    double? tokensPerSec,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      thought: thought ?? this.thought,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentType: attachmentType ?? this.attachmentType,
      tokensPerSec: tokensPerSec ?? this.tokensPerSec,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'thought': thought,
        'attachmentName': attachmentName,
        'attachmentType': attachmentType,
        'tokensPerSec': tokensPerSec,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        role: json['role'] as String,
        content: json['content'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        thought: json['thought'] as String?,
        attachmentName: json['attachmentName'] as String?,
        attachmentType: json['attachmentType'] as String?,
        tokensPerSec: (json['tokensPerSec'] as num?)?.toDouble(),
      );
}

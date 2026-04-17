/// Sub-model: Poll option
class PollOption {
  final String id;
  final String text;

  const PollOption({required this.id, required this.text});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'text': text};
}

/// Supabase table: polls
class PollModel {
  final String pollId;
  final String chatId;
  final String messageId;
  final String question;
  final List<PollOption> options;
  final Map<String, List<String>> votes;  // optionId → [userId]
  final bool isAnonymous;
  final bool isMultipleChoice;
  final bool isQuiz;
  final String? correctOptionId;          // only if isQuiz = true
  final String? explanation;
  final DateTime? closedAt;
  final String createdBy;
  final DateTime? createdAt;

  const PollModel({
    required this.pollId,
    required this.chatId,
    required this.messageId,
    required this.question,
    required this.options,
    this.votes = const {},
    this.isAnonymous = false,
    this.isMultipleChoice = false,
    this.isQuiz = false,
    this.correctOptionId,
    this.explanation,
    this.closedAt,
    required this.createdBy,
    this.createdAt,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      pollId: json['poll_id'] as String? ?? json['pollId'] as String? ?? json['id'] as String? ?? '',
      chatId: json['chat_id'] as String? ?? json['chatId'] as String? ?? '',
      messageId: json['message_id'] as String? ?? json['messageId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: json['options'] != null
          ? (json['options'] as List)
              .map((e) => PollOption.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      votes: json['votes'] != null
          ? (json['votes'] as Map).map(
              (k, v) => MapEntry(k.toString(), List<String>.from(v ?? [])))
          : {},
      isAnonymous: json['is_anonymous'] as bool? ?? json['isAnonymous'] as bool? ?? false,
      isMultipleChoice: json['is_multiple_choice'] as bool? ?? json['isMultipleChoice'] as bool? ?? false,
      isQuiz: json['is_quiz'] as bool? ?? json['isQuiz'] as bool? ?? false,
      correctOptionId: json['correct_option_id'] as String? ?? json['correctOptionId'] as String?,
      explanation: json['explanation'] as String?,
      closedAt: _parseDateTime(json['closed_at'] ?? json['closedAt']),
      createdBy: json['created_by'] as String? ?? json['createdBy'] as String? ?? '',
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  /// Convert to Supabase-compatible JSON (snake_case)
  Map<String, dynamic> toJson() => {
    'id': pollId,
    'chat_id': chatId,
    'message_id': messageId,
    'question': question,
    'options': options.map((o) => o.toJson()).toList(),
    'votes': votes,
    'is_anonymous': isAnonymous,
    'is_multiple_choice': isMultipleChoice,
    'is_quiz': isQuiz,
    'correct_option_id': correctOptionId,
    'explanation': explanation,
    'closed_at': closedAt?.toIso8601String(),
    'created_by': createdBy,
    'created_at': createdAt?.toIso8601String(),
  };

  /// Total vote count across all options
  int get totalVotes => votes.values.fold(0, (total, list) => total + list.length);

  /// Get vote count for a specific option
  int voteCountFor(String optionId) => votes[optionId]?.length ?? 0;

  /// Check if a user has voted
  bool hasUserVoted(String userId) =>
      votes.values.any((voters) => voters.contains(userId));

  PollModel copyWith({
    String? pollId, String? chatId, String? messageId, String? question,
    List<PollOption>? options, Map<String, List<String>>? votes,
    bool? isAnonymous, bool? isMultipleChoice, bool? isQuiz,
    String? correctOptionId, String? explanation, DateTime? closedAt,
    String? createdBy, DateTime? createdAt,
  }) {
    return PollModel(
      pollId: pollId ?? this.pollId,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      question: question ?? this.question,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isMultipleChoice: isMultipleChoice ?? this.isMultipleChoice,
      isQuiz: isQuiz ?? this.isQuiz,
      correctOptionId: correctOptionId ?? this.correctOptionId,
      explanation: explanation ?? this.explanation,
      closedAt: closedAt ?? this.closedAt,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

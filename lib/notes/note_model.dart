import 'dart:convert';

class Note {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool pinned;
  final DateTime? reminderAt;
  final int? notificationId;

  const Note({
    required this.id,
    required this.text,
    required this.createdAt,
    this.pinned = false,
    this.reminderAt,
    this.notificationId,
  });

  Note copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    bool? pinned,
    DateTime? reminderAt,
    int? notificationId,
  }) {
    return Note(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      pinned: pinned ?? this.pinned,
      reminderAt: reminderAt,
      notificationId: notificationId,
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      text: map['text'],
      createdAt: DateTime.parse(map['createdAt']),
      pinned: map['pinned'] ?? false,
      reminderAt: map['reminderAt'] != null
          ? DateTime.parse(map['reminderAt'])
          : null,
      notificationId: map['notificationId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'pinned': pinned,
      'reminderAt': reminderAt?.toIso8601String(),
      'notificationId': notificationId,
    };
  }

  static List<Note> decodeList(String raw) {
    final List data = jsonDecode(raw);
    return data.map((e) => Note.fromMap(e)).toList();
  }

  static String encodeList(List<Note> notes) {
    return jsonEncode(notes.map((e) => e.toMap()).toList());
  }
}

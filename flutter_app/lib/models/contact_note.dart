import '../core/json_utils.dart';

class ContactNoteAuthor {
  const ContactNoteAuthor({
    required this.id,
    required this.fullName,
    required this.role,
  });

  final int id;
  final String fullName;
  final String role;

  factory ContactNoteAuthor.fromJson(Map<String, dynamic> json) {
    return ContactNoteAuthor(
      id: toInt(json['id']),
      fullName: (json['fullName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }
}

class ContactNote {
  const ContactNote({
    required this.id,
    required this.channel,
    required this.note,
    this.bookingId,
    this.createdAt,
    this.author,
  });

  final int id;
  final String channel;
  final String note;
  final int? bookingId;
  final DateTime? createdAt;
  final ContactNoteAuthor? author;

  factory ContactNote.fromJson(Map<String, dynamic> json) {
    final author = json['author'];
    return ContactNote(
      id: toInt(json['id']),
      channel: (json['channel'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      bookingId: json['bookingId'] == null ? null : toInt(json['bookingId']),
      createdAt: parseDate(json['createdAt']),
      author: author is Map<String, dynamic>
          ? ContactNoteAuthor.fromJson(author)
          : null,
    );
  }

  static List<ContactNote> listFromJson(dynamic value) {
    if (value is! List) return const <ContactNote>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(ContactNote.fromJson)
        .toList();
  }
}

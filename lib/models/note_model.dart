class Note {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final String? deadline;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'deadline': deadline,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['createdAt'],
      deadline: map['deadline'],
    );
  }
}
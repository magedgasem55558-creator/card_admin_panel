import 'package:cloud_firestore/cloud_firestore.dart';

class Lecture {
  final String id;
  final String title;
  final String speaker;
  final String? time;
  final DateTime? createdAt;

  Lecture({
    required this.id,
    required this.title,
    required this.speaker,
    this.time,
    this.createdAt,
  });

  factory Lecture.fromMap(String id, Map<String, dynamic> data) {
    return Lecture(
      id: id,
      title: data['title'] ?? '',
      speaker: data['speaker'] ?? '',
      time: data['time'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
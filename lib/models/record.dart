import 'package:cloud_firestore/cloud_firestore.dart';

class Record {
  final String id;
  final String studentId;
  final String studentName;
  final String status;
  final String? surah;
  final String? fromAyah;
  final String? toAyah;
  final List<String> grades;      // ✅ أصبحت قائمة
  final String tomorrowRequirement;
  final String notes;
  final int pointsGiven;
  final int linesGiven;
  final String? date;
  final DateTime? timestamp;

  Record({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.status,
    this.surah,
    this.fromAyah,
    this.toAyah,
    required this.grades,
    required this.tomorrowRequirement,
    required this.notes,
    this.pointsGiven = 0,
    this.linesGiven = 0,
    this.date,
    this.timestamp,
  });

  factory Record.fromMap(String id, Map<String, dynamic> data, String studentName) {
    // معالجة grade كمصفوفة أو نص قديم وتحويله إلى قائمة
    List<String> parsedGrades = [];
    final rawGrade = data['grade'];
    if (rawGrade is List) {
      parsedGrades = rawGrade.cast<String>();
    } else if (rawGrade is String && rawGrade.isNotEmpty) {
      parsedGrades = [rawGrade];
    }

    return Record(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: studentName,
      status: data['status'] ?? 'حاضر',
      surah: data['surah'],
      fromAyah: data['fromAyah']?.toString(),
      toAyah: data['toAyah']?.toString(),
      grades: parsedGrades,
      tomorrowRequirement: data['tomorrowRequirement'] ?? '',
      notes: data['notes'] ?? '',
      pointsGiven: data['pointsGiven'] ?? 0,
      linesGiven: data['linesGiven'] ?? 0,
      date: data['date'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }
}
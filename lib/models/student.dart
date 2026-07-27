import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String name;
  final String? parentId;
  final String? halaqaId;
  String? halaqaName;
  final int totalPoints;
  final int totalLines;
  final bool isActive;
  final DateTime? joinDate;

  Student({
    required this.id,
    required this.name,
    this.parentId,
    this.halaqaId,
    this.halaqaName,
    this.totalPoints = 0,
    this.totalLines = 0,
    this.isActive = true,
    this.joinDate,
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    // معالجة joinDate الذي قد يكون Timestamp أو String
    DateTime? parsedJoinDate;
    final rawJoinDate = data['joinDate'];
    if (rawJoinDate is Timestamp) {
      parsedJoinDate = rawJoinDate.toDate();
    } else if (rawJoinDate is String) {
      parsedJoinDate = DateTime.tryParse(rawJoinDate);
    }

    return Student(
      id: id,
      name: data['name'] ?? '',
      parentId: data['parentId'],
      halaqaId: data['halaqaId'],
      totalPoints: data['totalPoints'] ?? 0,
      totalLines: data['totalLines'] ?? 0,
      isActive: data['isActive'] ?? true,
      joinDate: parsedJoinDate,
    );
  }
}
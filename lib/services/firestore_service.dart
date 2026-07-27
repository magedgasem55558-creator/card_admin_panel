import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import '../models/halaqa.dart';
import '../models/record.dart';
import '../models/lecture.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- التحقق من صلاحية المدير ---
  Future<bool> isAdmin(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }

  // --- الحلقات ---
  Future<List<Halaqa>> loadHalaqatList() async {
    final snap = await _db.collection('halaqat').get();
    return snap.docs.map((d) => Halaqa.fromMap(d.id, d.data())).toList();
  }

  Future<void> addHalaqa(Map<String, dynamic> data) {
    return _db.collection('halaqat').add(data);
  }

  Future<void> updateHalaqa(String id, Map<String, dynamic> data) {
    return _db.collection('halaqat').doc(id).update(data);
  }

  Future<void> deleteHalaqa(String id) {
    return _db.collection('halaqat').doc(id).delete();
  }

  // --- الطلاب ---
  Future<List<Student>> loadAllStudents() async {
    final snap = await _db.collection('students').get();
    final students = <Student>[];
    for (var doc in snap.docs) {
      final student = Student.fromMap(doc.id, doc.data());
      if (student.halaqaId != null) {
        final halaqa = await _db.collection('halaqat').doc(student.halaqaId).get();
        student.halaqaName = halaqa.data()?['name'] ?? 'بدون حلقة';
      } else {
        student.halaqaName = 'بدون حلقة';
      }
      students.add(student);
    }
    return students;
  }

  /// جلب الطلاب المنتمين إلى حلقة معينة
  Future<List<Student>> loadStudentsByHalaqa(String halaqaId) async {
    final snap = await _db
        .collection('students')
        .where('halaqaId', isEqualTo: halaqaId)
        .get();
    return snap.docs
        .map((d) => Student.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> addStudent(Map<String, dynamic> data) {
    return _db.collection('students').add(data);
  }

  Future<void> updateStudent(String id, Map<String, dynamic> data) {
    return _db.collection('students').doc(id).update(data);
  }

  Future<void> deleteStudent(String id) async {
    // حذف سجلاته أولاً (اختياري)
    final records = await _db.collection('records').where('studentId', isEqualTo: id).get();
    for (var rec in records.docs) {
      await rec.reference.delete();
    }
    return _db.collection('students').doc(id).delete();
  }

  // --- أولياء الأمور ---
  Future<String?> getParentIdByEmail(String email) async {
    final snap = await _db.collection('parents').where('email', isEqualTo: email).limit(1).get();
    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }

  Future<void> createParent(String uid, String email) {
    return _db.collection('parents').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- السجلات ---
  Future<List<Record>> loadAllRecords() async {
    final snap = await _db.collection('records').orderBy('timestamp', descending: true).get();
    final records = <Record>[];
    for (var doc in snap.docs) {
      final data = doc.data();
      String studentName = 'طالب محذوف';
      if (data['studentId'] != null) {
        final stuDoc = await _db.collection('students').doc(data['studentId']).get();
        if (stuDoc.exists) studentName = stuDoc.data()?['name'] ?? 'طالب محذوف';
      }
      records.add(Record.fromMap(doc.id, data, studentName));
    }
    return records;
  }

  Future<void> addRecord(Map<String, dynamic> data) {
    return _db.collection('records').add(data);
  }

  Future<void> updateRecord(String id, Map<String, dynamic> data) {
    return _db.collection('records').doc(id).update(data);
  }

  Future<void> deleteRecord(String id) {
    return _db.collection('records').doc(id).delete();
  }

  // --- المحاضرات ---
  Future<List<Lecture>> loadAllLectures() async {
    final snap = await _db.collection('lectures').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Lecture.fromMap(d.id, d.data())).toList();
  }

  Future<void> addLecture(Map<String, dynamic> data) {
    return _db.collection('lectures').add(data);
  }

  Future<void> updateLecture(String id, Map<String, dynamic> data) {
    return _db.collection('lectures').doc(id).update(data);
  }

  Future<void> deleteLecture(String id) {
    return _db.collection('lectures').doc(id).delete();
  }

  // --- الإعدادات ---
  Future<Map<String, dynamic>?> loadSetting(String docId) async {
    final doc = await _db.collection('settings').doc(docId).get();
    return doc.data();
  }

  Future<void> updateSetting(String docId, Map<String, dynamic> data) {
    return _db.collection('settings').doc(docId).set(data, SetOptions(merge: true));
  }

  Future<void> deleteSetting(String docId) {
    return _db.collection('settings').doc(docId).delete();
  }

  // --- التبرعات ---
  Future<Map<String, dynamic>?> loadDonationInfo() => loadSetting('donation_info');
  Future<void> updateDonationInfo(Map<String, dynamic> data) => updateSetting('donation_info', data);
}
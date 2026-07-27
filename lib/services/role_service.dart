import 'package:cloud_firestore/cloud_firestore.dart';

class RoleService {
  Future<bool> checkAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && doc.data()?['role'] == 'admin';
  }
}
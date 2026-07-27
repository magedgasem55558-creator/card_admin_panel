import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});
  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _selectedHalaqaId;
  List<Map<String, dynamic>> _halaqat = [];

  @override
  void initState() {
    super.initState();
    _loadHalaqat();
  }

  Future<void> _loadHalaqat() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadHalaqatList();
    setState(() {
      _halaqat = list.map((h) => {'id': h.id, 'name': h.name}).toList();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (name.isEmpty || email.isEmpty || pass.isEmpty || _selectedHalaqaId == null) {
      _showMsg('يرجى ملء جميع الحقول');
      return;
    }
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      String parentUid;
      try {
        final cred = await auth.signUp(email, pass);
        parentUid = cred!.uid;
        await firestore.createParent(parentUid, email);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          final existingId = await firestore.getParentIdByEmail(email);
          if (existingId == null) throw Exception('البريد موجود لكن لا يوجد ولي أمر مسجل');
          parentUid = existingId;
        } else {
          rethrow;
        }
      }
      await firestore.addStudent({
        'name': name,
        'parentId': parentUid,
        'halaqaId': _selectedHalaqaId,
        'totalPoints': 0,
        'totalLines': 0,
        'joinDate': FieldValue.serverTimestamp(),
        'isActive': true,
      });
      _showMsg('تمت إضافة $name بنجاح ✅');
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      setState(() => _selectedHalaqaId = null);
    } catch (e) {
      _showMsg('خطأ: $e');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة طالب وولي أمر')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          child: ListView(
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم الطالب')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedHalaqaId,
                items: _halaqat
                    .map<DropdownMenuItem<String>>(
                      (h) => DropdownMenuItem<String>(
                        value: h['id'] as String,
                        child: Text(h['name'] as String),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedHalaqaId = v),
                decoration: const InputDecoration(labelText: 'الحلقة'),
              ),
              const SizedBox(height: 12),
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'بريد ولي الأمر')),
              const SizedBox(height: 12),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _save, child: const Text('✅ حفظ البيانات')),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHalaqat();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHalaqat() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadHalaqatList();
    setState(() {
      _halaqat = list.map((h) => {'id': h.id, 'name': h.name}).toList();
    });
  }

  // دالة إنشاء حساب ولي الأمر بدون تسجيل خروج الأدمن
  Future<String?> _createParentAccount(String email, String password) async {
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );

    try {
      final authInstance = FirebaseAuth.instanceFor(app: secondaryApp);
      final cred = await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user?.uid;
      await secondaryApp.delete();
      return uid;
    } catch (e) {
      await secondaryApp.delete();
      rethrow;
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase(); // تحويل البريد لصغير للتطابق
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || _selectedHalaqaId == null) {
      _showMsg('يرجى ملء جميع الحقول');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = Provider.of<FirestoreService>(context, listen: false);
      String parentUid;

      try {
        // إنشاء الحساب عبر التطبيق الثانوي لمنع خطأ PigeonUserDetails
        final uid = await _createParentAccount(email, pass);
        if (uid == null) throw Exception('فشل في إنشاء حساب ولي الأمر');
        
        parentUid = uid;
        await firestore.createParent(parentUid, email);

      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // إذا كان البريد مستخدماً مسبقاً، نجلب UID الخاص بولي الأمر من Firestore
          final existingId = await firestore.getParentIdByEmail(email);
          
          if (existingId == null) {
            // في حال وجود الحساب في Auth وعدم وجوده في Firestore، نربطه بـ FirebaseAuth
            throw Exception('البريد الإلكتروني موجود مسبقاً كحساب مستقل. يرجى التأكد من بيانات ولي الأمر.');
          }
          parentUid = existingId;
        } else {
          rethrow;
        }
      }

      // إضافة الطالب بعد الحصول على parentUid
      await firestore.addStudent({
        'name': name,
        'parentId': parentUid,
        'halaqaId': _selectedHalaqaId,
        'totalPoints': 0,
        'totalLines': 0,
        'joinDate': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _showMsg('تمت إضافة الطالب ($name) بنجاح ✅');
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
      setState(() => _selectedHalaqaId = null);

    } catch (e) {
      _showMsg('خطأ: $e');
    } finally {
      setState(() => _isLoading = false);
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
        child: ListView(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'اسم الطالب الرباعي'),
            ),
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
              decoration: const InputDecoration(labelText: 'اختر الحلقة'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'بريد ولي الأمر'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('✅ حفظ البيانات'),
            ),
          ],
        ),
      ),
    );
  }
}

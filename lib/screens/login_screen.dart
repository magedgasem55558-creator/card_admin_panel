import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  Future<void> _login() async {
    setState(() { _error = ''; _loading = true; });
    try {
      final auth = AuthService();
      await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      // سيتم توجيه المستخدم تلقائياً بواسطة app.dart StreamBuilder
    } on FirebaseAuthException catch (e) {
      String msg = 'فشل تسجيل الدخول';
      switch (e.code) {
        case 'user-not-found': msg = '❌ لا يوجد حساب بهذا البريد'; break;
        case 'wrong-password': msg = '❌ كلمة مرور غير صحيحة'; break;
        case 'too-many-requests': msg = '🚫 تم تعطيل الحساب مؤقتاً'; break;
      }
      setState(() => _error = msg);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏛️ مرحباً بك', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'البريد الإلكتروني')),
                  const SizedBox(height: 16),
                  TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(onPressed: _login, child: const Text('دخول')),
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(_error, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

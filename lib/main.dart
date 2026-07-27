import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC06KKxkehT1uPBT9k-r-d6MmB4RUuVy9Y",
      authDomain: "mosque-system.firebaseapp.com",
      projectId: "mosque-system",
      storageBucket: "mosque-system.firebasestorage.app",
      messagingSenderId: "905816133159",
      appId: "1:905816133159:web:3b95d858815f91780e0802",
    ),
  );
  runApp(const MyApp());
}
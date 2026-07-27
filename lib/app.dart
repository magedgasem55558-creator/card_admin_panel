import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'services/firestore_service.dart';
import 'services/role_service.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<RoleService>(create: (_) => RoleService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'إدارة المسجد',
        theme: ThemeData(
          fontFamily: 'Cairo', // تأكد من إضافة الخط في pubspec.yaml لو أردت
          primarySwatch: Colors.teal,
          scaffoldBackgroundColor: const Color(0xFFF0FDF4),
        ),
        home: StreamBuilder(
          stream: AuthService().authStateChanges,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.active) {
              final user = snapshot.data;
              if (user != null) return const HomeScreen();
              return const LoginScreen();
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
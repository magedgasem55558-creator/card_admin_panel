import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/role_service.dart';
import 'add_student_screen.dart';
import 'recitation_screen.dart';
import 'events_screen.dart';
import 'khutba_screen.dart';
import 'add_halaqa_screen.dart';
import 'lectures_screen.dart';
import 'donations_screen.dart';
import 'manage_students_screen.dart';
import 'manage_halaqat_screen.dart';
import 'manage_records_screen.dart';
import 'manage_lectures_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentRoute = 'add_student';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final role = Provider.of<RoleService>(context, listen: false);
    if (auth.currentUserId != null) {
      final admin = await role.checkAdmin(auth.currentUserId!);
      setState(() => _isAdmin = admin || auth.currentUserEmail == 'hammed@gmail.com');
    }
  }

  Widget _buildPage() {
    switch (_currentRoute) {
      case 'add_student': return const AddStudentScreen();
      case 'recitation': return const RecitationScreen();
      case 'events': return const EventsScreen();
      case 'khutba': return const KhutbaScreen();
      case 'add_halaqa': return const AddHalaqaScreen();
      case 'lectures': return const LecturesScreen();
      case 'donations': return const DonationsScreen();
      case 'manage_students': return const ManageStudentsScreen();
      case 'manage_halaqat': return const ManageHalaqatScreen();
      case 'manage_records': return const ManageRecordsScreen();
      case 'manage_lectures': return const ManageLecturesScreen();
      default: return const AddStudentScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المسجد')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🏛️ إدارة المسجد', style: TextStyle(color: Colors.white, fontSize: 20)),
                  const SizedBox(height: 8),
                  Text('📧 ${Provider.of<AuthService>(context).currentUserEmail}', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _drawerItem('👥 إضافة طالب', 'add_student'),
            _drawerItem('📖 رصد التسميع', 'recitation'),
            _drawerItem('📅 الفعاليات', 'events'),
            _drawerItem('🕌 خطبة الجمعة', 'khutba'),
            _drawerItem('🏫 إضافة حلقة', 'add_halaqa'),
            _drawerItem('💳 التبرعات', 'donations'),
            _drawerItem('🎤 المحاضرات', 'lectures'),
            const Divider(),
            if (_isAdmin) ...[
              _drawerItem('📋 إدارة الطلاب', 'manage_students'),
              _drawerItem('📋 إدارة الحلقات', 'manage_halaqat'),
              _drawerItem('📋 سجلات التسميع', 'manage_records'),
              _drawerItem('📋 إدارة المحاضرات', 'manage_lectures'),
            ],
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                await Provider.of<AuthService>(context, listen: false).signOut();
                // سيعيد التوجيه تلقائياً
              },
            ),
          ],
        ),
      ),
      body: _buildPage(),
    );
  }

  ListTile _drawerItem(String title, String route) {
    return ListTile(
      title: Text(title),
      onTap: () {
        setState(() => _currentRoute = route);
        Navigator.pop(context);
      },
    );
  }
}
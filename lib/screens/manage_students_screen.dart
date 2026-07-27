import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../services/firestore_service.dart';

class ManageStudentsScreen extends StatefulWidget {
  const ManageStudentsScreen({super.key});

  @override
  State<ManageStudentsScreen> createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  List<Student> _allStudents = [];
  List<Student> _filtered = [];
  bool _isLoading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final students = await service.loadAllStudents();
      if (!mounted) return;
      setState(() {
        _allStudents = students;
        _filtered = students;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في جلب الطلاب: $e')),
      );
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = _allStudents
          .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _resetAllPoints() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير النقاط'),
        content: const Text('سيتم تصفير نقاط جميع الطلاب. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    final service = Provider.of<FirestoreService>(context, listen: false);
    int failedCount = 0;

    for (var student in _allStudents) {
      try {
        await service.updateStudent(student.id, {'totalPoints': 0});
      } catch (e) {
        failedCount++;
        debugPrint('فشل تصفير ${student.name}: $e');
      }
    }

    await _loadStudents();

    if (!mounted) return;

    if (failedCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تصفير النقاط، ولكن تعذّر تحديث $failedCount طالب.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تصفير جميع النقاط ✅')),
      );
    }
  }

  Future<void> _editStudent(Student student) async {
    final nameCtrl = TextEditingController(text: student.name);
    final pointsCtrl =
        TextEditingController(text: student.totalPoints.toString());
    final linesCtrl =
        TextEditingController(text: student.totalLines.toString()); // 👈 أسطر الطالب
    bool isActive = student.isActive;
    String? halaqaId = student.halaqaId;

    final service = Provider.of<FirestoreService>(context, listen: false);
    final halaqas = await service.loadHalaqatList();
    final halaqat = halaqas.map((h) => {'id': h.id, 'name': h.name}).toList();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل بيانات الطالب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: halaqaId,
                  items: halaqat
                      .map<DropdownMenuItem<String>>(
                        (h) => DropdownMenuItem<String>(
                          value: h['id'],
                          child: Text(h['name']!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setDialogState(() => halaqaId = v),
                  decoration: const InputDecoration(labelText: 'الحلقة'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'النقاط'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: linesCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'إجمالي الأسطر'), // 👈 حقل عدد الأسطر
                ),
                SwitchListTile(
                  title: const Text('نشط'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                await service.updateStudent(student.id, {
                  'name': nameCtrl.text.trim(),
                  'halaqaId': halaqaId,
                  'totalPoints': int.tryParse(pointsCtrl.text) ?? 0,
                  'totalLines': int.tryParse(linesCtrl.text) ?? 0, // 👈 حفظ إجمالي الأسطر
                  'isActive': isActive,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                _loadStudents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم التعديل ✅')),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteStudent(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الطالب'),
        content: Text('هل تريد حذف ${student.name} وجميع سجلاته؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteStudent(student.id);
      if (!mounted) return;
      _loadStudents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الطلاب')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _filter,
                    decoration: const InputDecoration(
                      labelText: 'ابحث عن طالب...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _resetAllPoints,
                  child: const Text('🔄 تصفير النقاط'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('لا يوجد طلاب مسجلين'))
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final student = _filtered[index];
                          return ListTile(
                            title: Text(student.name),
                            subtitle: Text(
                              'الحلقة: ${student.halaqaName ?? "غير محددة"} | النقاط: ${student.totalPoints} | الأسطر: ${student.totalLines} | ${student.isActive ? "نشط" : "غير نشط"}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editStudent(student),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _deleteStudent(student),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

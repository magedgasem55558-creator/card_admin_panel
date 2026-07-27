import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/lecture.dart';
import '../services/firestore_service.dart';

class ManageLecturesScreen extends StatefulWidget {
  const ManageLecturesScreen({super.key});
  @override
  State<ManageLecturesScreen> createState() => _ManageLecturesScreenState();
}

class _ManageLecturesScreenState extends State<ManageLecturesScreen> {
  List<Lecture> _lectures = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadAllLectures();
    setState(() => _lectures = list);
  }

  Future<void> _editLecture(Lecture lecture) async {
    final titleCtrl = TextEditingController(text: lecture.title);
    final speakerCtrl = TextEditingController(text: lecture.speaker);
    DateTime? time = lecture.time != null ? DateTime.tryParse(lecture.time!) : null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل المحاضرة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان')),
              TextField(controller: speakerCtrl, decoration: const InputDecoration(labelText: 'المحاضر')),
              ListTile(
                title: Text(time != null ? 'الوقت: ${time!.toLocal().toString().substring(0,16)}' : 'اختر الوقت'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: ctx, initialDate: time ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                  if (d != null) {
                    final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.fromDateTime(time ?? DateTime.now()));
                    if (t != null) {
                      setDialogState(() => time = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(onPressed: () async {
              final service = Provider.of<FirestoreService>(context, listen: false);
              await service.updateLecture(lecture.id, {
                'title': titleCtrl.text.trim(),
                'speaker': speakerCtrl.text.trim(),
                'time': time?.toIso8601String(),
              });
              Navigator.pop(ctx);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل ✅')));
            }, child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteLecture(Lecture lecture) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('حذف المحاضرة'), content: const Text('هل تريد حذف هذه المحاضرة؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
      ],
    ));
    if (confirm == true) {
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteLecture(lecture.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المحاضرات')),
      body: ListView.builder(
        itemCount: _lectures.length,
        itemBuilder: (context, index) {
          final l = _lectures[index];
          return ListTile(
            title: Text('🎤 ${l.title}'),
            subtitle: Text('المحاضر: ${l.speaker} | الوقت: ${l.time ?? "غير محدد"}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editLecture(l)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteLecture(l)),
              ],
            ),
          );
        },
      ),
    );
  }
}
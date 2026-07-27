import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class LecturesScreen extends StatefulWidget {
  const LecturesScreen({super.key});
  @override
  State<LecturesScreen> createState() => _LecturesScreenState();
}

class _LecturesScreenState extends State<LecturesScreen> {
  final _titleCtrl = TextEditingController();
  final _speakerCtrl = TextEditingController();
  DateTime? _lectureTime;

  Future<void> _addLecture() async {
    if (_titleCtrl.text.isEmpty || _speakerCtrl.text.isEmpty || _lectureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.addLecture({
      'title': _titleCtrl.text.trim(),
      'speaker': _speakerCtrl.text.trim(),
      'time': _lectureTime!.toIso8601String(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر المحاضرة ✅')));
    _titleCtrl.clear();
    _speakerCtrl.clear();
    setState(() => _lectureTime = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة محاضرة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان المحاضرة')),
            const SizedBox(height: 12),
            TextField(controller: _speakerCtrl, decoration: const InputDecoration(labelText: 'اسم المحاضر')),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_lectureTime != null ? 'الوقت: ${_lectureTime!.toLocal().toString().substring(0, 16)}' : 'اختر التاريخ والوقت'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _lectureTime ?? DateTime.now(),
                    firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) {
                  final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_lectureTime ?? DateTime.now()));
                  if (time != null) {
                    setState(() {
                      _lectureTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addLecture, child: const Text('📢 نشر الإعلان')),
          ],
        ),
      ),
    );
  }
}
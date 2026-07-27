import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});
  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  DateTime? _eventDate;

  @override
  void initState() {
    super.initState();
    _loadCurrentEvent();
  }

  Future<void> _loadCurrentEvent() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final event = await service.loadSetting('next_event');
    if (event != null) {
      _titleCtrl.text = event['title'] ?? '';
      _locationCtrl.text = event['location'] ?? '';
      if (event['date'] != null) {
        _eventDate = DateTime.tryParse(event['date']);
      }
      setState(() {});
    }
  }

  Future<void> _updateEvent() async {
    if (_titleCtrl.text.isEmpty || _locationCtrl.text.isEmpty || _eventDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.updateSetting('next_event', {
      'title': _titleCtrl.text,
      'location': _locationCtrl.text,
      'date': _eventDate!.toIso8601String(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الفعالية ✅')));
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'), content: const Text('هل تريد حذف الفعالية الحالية؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))],
    ));
    if (confirm == true) {
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteSetting('next_event');
      _titleCtrl.clear();
      _locationCtrl.clear();
      setState(() => _eventDate = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفعاليات القادمة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الفعالية')),
            const SizedBox(height: 12),
            TextField(controller: _locationCtrl, decoration: const InputDecoration(labelText: 'المكان')),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_eventDate != null
                  ? 'التاريخ: ${_eventDate!.toLocal().toString().substring(0, 16)}'
                  : 'اختر التاريخ والوقت'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(context: context, initialDate: _eventDate ?? DateTime.now(),
                    firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (pickedDate != null) {
                  final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_eventDate ?? DateTime.now()));
                  if (pickedTime != null) {
                    setState(() {
                      _eventDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _updateEvent, child: const Text('📢 تحديث الفعالية'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: _deleteEvent, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('🗑️ حذف'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
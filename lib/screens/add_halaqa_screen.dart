import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class AddHalaqaScreen extends StatefulWidget {
  const AddHalaqaScreen({super.key});
  @override
  State<AddHalaqaScreen> createState() => _AddHalaqaScreenState();
}

class _AddHalaqaScreenState extends State<AddHalaqaScreen> {
  final _nameCtrl = TextEditingController();
  final _teacherCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty || _teacherCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إكمال كافة البيانات')));
      return;
    }
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.addHalaqa({
      'name': _nameCtrl.text.trim(),
      'teacherName': _teacherCtrl.text.trim(),
      'teacherPhone': _phoneCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الحلقة بنجاح ✅')));
    _nameCtrl.clear();
    _teacherCtrl.clear();
    _phoneCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة حلقة جديدة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'اسم الحلقة')),
            const SizedBox(height: 12),
            TextField(controller: _teacherCtrl, decoration: const InputDecoration(labelText: 'اسم المدرس')),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم واتساب المدرس')),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('💾 حفظ الحلقة')),
          ],
        ),
      ),
    );
  }
}
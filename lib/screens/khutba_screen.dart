import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KhutbaScreen extends StatefulWidget {
  const KhutbaScreen({super.key});
  @override
  State<KhutbaScreen> createState() => _KhutbaScreenState();
}

class _KhutbaScreenState extends State<KhutbaScreen> {
  final _titleCtrl = TextEditingController();
  final _imamCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentKhutba();
  }

  Future<void> _loadCurrentKhutba() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final khutba = await service.loadSetting('next_khutba');
    if (khutba != null) {
      _titleCtrl.text = khutba['title'] ?? '';
      _imamCtrl.text = khutba['imam'] ?? '';
    }
  }

  Future<void> _updateKhutba() async {
    if (_titleCtrl.text.isEmpty || _imamCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول')));
      return;
    }
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.updateSetting('next_khutba', {
      'title': _titleCtrl.text,
      'imam': _imamCtrl.text,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الخطبة ✅')));
  }

  Future<void> _deleteKhutba() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('تأكيد الحذف'), content: const Text('هل تريد حذف خطبة الجمعة الحالية؟'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف'))],
    ));
    if (confirm == true) {
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteSetting('next_khutba');
      _titleCtrl.clear();
      _imamCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خطبة الجمعة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الخطبة')),
            const SizedBox(height: 12),
            TextField(controller: _imamCtrl, decoration: const InputDecoration(labelText: 'اسم الخطيب')),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: _updateKhutba, child: const Text('📝 تحديث'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: _deleteKhutba, style: OutlinedButton.styleFrom(foregroundColor: Colors.red), child: const Text('🗑️ حذف'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
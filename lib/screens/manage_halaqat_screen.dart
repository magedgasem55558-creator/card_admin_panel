import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/halaqa.dart';
import '../services/firestore_service.dart';

class ManageHalaqatScreen extends StatefulWidget {
  const ManageHalaqatScreen({super.key});
  @override
  State<ManageHalaqatScreen> createState() => _ManageHalaqatScreenState();
}

class _ManageHalaqatScreenState extends State<ManageHalaqatScreen> {
  List<Halaqa> _halaqat = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadHalaqatList();
    setState(() => _halaqat = list);
  }

  Future<void> _editHalaqa(Halaqa halaqa) async {
    final nameCtrl = TextEditingController(text: halaqa.name);
    final teacherCtrl = TextEditingController(text: halaqa.teacherName);
    final phoneCtrl = TextEditingController(text: halaqa.teacherPhone ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الحلقة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'اسم الحلقة')),
            TextField(controller: teacherCtrl, decoration: const InputDecoration(labelText: 'اسم الشيخ')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'رقم الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () async {
            final service = Provider.of<FirestoreService>(context, listen: false);
            await service.updateHalaqa(halaqa.id, {
              'name': nameCtrl.text.trim(),
              'teacherName': teacherCtrl.text.trim(),
              'teacherPhone': phoneCtrl.text.trim(),
            });
            Navigator.pop(ctx);
            _loadData();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التعديل ✅')));
          }, child: const Text('حفظ')),
        ],
      ),
    );
  }

  Future<void> _deleteHalaqa(Halaqa halaqa) async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('حذف الحلقة'), content: Text('سيتم حذف "${halaqa.name}" وسيصبح طلابها بدون حلقة. متأكد؟'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
      ],
    ));
    if (confirm == true) {
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteHalaqa(halaqa.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحذف ✅')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الحلقات')),
      body: ListView.builder(
        itemCount: _halaqat.length,
        itemBuilder: (context, index) {
          final h = _halaqat[index];
          return ListTile(
            title: Text('🏫 ${h.name}'),
            subtitle: Text('الشيخ: ${h.teacherName} 📞 ${h.teacherPhone ?? ""}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editHalaqa(h)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHalaqa(h)),
              ],
            ),
          );
        },
      ),
    );
  }
}

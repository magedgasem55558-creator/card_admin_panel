import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../services/firestore_service.dart';

class ManageRecordsScreen extends StatefulWidget {
  const ManageRecordsScreen({super.key});
  @override
  State<ManageRecordsScreen> createState() => _ManageRecordsScreenState();
}

class _ManageRecordsScreenState extends State<ManageRecordsScreen> {
  List<Record> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final list = await service.loadAllRecords();
      if (!mounted) return;
      setState(() {
        _records = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  Future<void> _editRecord(Record record) async {
    final surahCtrl = TextEditingController(text: record.surah);
    final fromCtrl = TextEditingController(text: record.fromAyah);
    final toCtrl = TextEditingController(text: record.toAyah);
    final pointsCtrl = TextEditingController(text: record.pointsGiven.toString());
    final linesCtrl = TextEditingController(text: record.linesGiven.toString());
    String status = record.status;
    List<String> selectedGrades = List.from(record.grades);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('تعديل السجل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الطالب: ${record.studentName}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'حاضر', child: Text('حاضر')),
                    DropdownMenuItem(value: 'غائب', child: Text('غائب')),
                    DropdownMenuItem(value: 'إجازة', child: Text('إجازة')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                  decoration: const InputDecoration(labelText: 'الحالة'),
                ),
                if (status == 'حاضر') ...[
                  TextField(controller: surahCtrl, decoration: const InputDecoration(labelText: 'السورة')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: fromCtrl, decoration: const InputDecoration(labelText: 'من'))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: toCtrl, decoration: const InputDecoration(labelText: 'إلى'))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('تقييم الأداء:'),
                  Wrap(
                    children: ['إتقان', 'تجويد', 'حفظ'].map((e) => FilterChip(
                      label: Text(e),
                      selected: selectedGrades.contains(e),
                      onSelected: (val) {
                        setDialogState(() {
                          if (val) {
                            selectedGrades.add(e);
                          } else {
                            selectedGrades.remove(e);
                          }
                        });
                      },
                    )).toList(),
                  ),
                ],
                TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: 'النقاط')),
                TextField(controller: linesCtrl, decoration: const InputDecoration(labelText: 'الأسطر')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final service = Provider.of<FirestoreService>(context, listen: false);
                await service.updateRecord(record.id, {
                  'status': status,
                  'surah': status == 'حاضر' ? surahCtrl.text.trim() : status,
                  'fromAyah': fromCtrl.text.trim(),
                  'toAyah': toCtrl.text.trim(),
                  'grade': selectedGrades, // قائمة التقييمات
                  'pointsGiven': int.tryParse(pointsCtrl.text) ?? 0,
                  'linesGiven': int.tryParse(linesCtrl.text) ?? 0,
                });
                Navigator.pop(ctx);
                _loadData();
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

  Future<void> _deleteRecord(Record record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف السجل'),
        content: const Text('هل تريد حذف هذا السجل؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      final service = Provider.of<FirestoreService>(context, listen: false);
      await service.deleteRecord(record.id);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف ✅')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجلات التسميع')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(child: Text('لا توجد سجلات حتى الآن'))
              : ListView.builder(
                  itemCount: _records.length,
                  itemBuilder: (context, index) {
                    final r = _records[index];
                    // عرض جميع التقييمات مفصولة بفاصلة عربية
                    String gradesText = r.grades.isEmpty ? '-' : r.grades.join('، ');
                    return ListTile(
                      title: Text('${r.studentName} - ${r.status}'),
                      subtitle: Text(
                        r.status == 'حاضر'
                            ? '${r.surah} (${r.fromAyah}-${r.toAyah}) | $gradesText | نقاط: ${r.pointsGiven}'
                            : '',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editRecord(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteRecord(r),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
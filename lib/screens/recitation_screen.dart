import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';

class RecitationScreen extends StatefulWidget {
  const RecitationScreen({super.key});
  @override
  State<RecitationScreen> createState() => _RecitationScreenState();
}

class _RecitationScreenState extends State<RecitationScreen> {
  String? _selectedHalaqa;
  String? _selectedStudent;
  final _surahCtrl = TextEditingController();
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _linesCountCtrl = TextEditingController();
  final _tomorrowCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');
  String _status = 'حاضر';
  final List<String> _evaluations = [];
  bool _showRecitationFields = true;

  List<Map<String, dynamic>> _halaqat = [];
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadHalaqat();
  }

  Future<void> _loadHalaqat() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadHalaqatList();
    setState(() => _halaqat = list.map((h) => {'id': h.id, 'name': '${h.name} - ${h.teacherName}'}).toList());
  }

  Future<void> _loadStudents(String halaqaId) async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final list = await service.loadStudentsByHalaqa(halaqaId);
    setState(() => _students = list.map((s) => {'id': s.id, 'name': s.name}).toList());
  }

  Future<void> _save() async {
    if (_selectedStudent == null || _selectedHalaqa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الحلقة والطالب أولاً')),
      );
      return;
    }

    final service = Provider.of<FirestoreService>(context, listen: false);

    // 🎯 تجهيز القائمة المختارة
    final evalList = List<String>.from(_evaluations);

    // 🎯 الهيكلية المتوافقة كلياً مع كود ولي الأمر القديم والجديد
    final data = {
      'date': DateTime.now().toIso8601String().split('T')[0],
      'grade': evalList,        // 👈 هذا ما يبحث عنه كود ولي الأمر القديم (data['grade'])
      'evaluation': evalList,   // 👈 التقييم بالمسمى الحديث لضمان التوافق المستقبلي
      'fromAyah': _showRecitationFields ? _fromCtrl.text.trim() : "",
      'toAyah': _showRecitationFields ? _toCtrl.text.trim() : "",
      'linesCount': _showRecitationFields ? (int.tryParse(_linesCountCtrl.text.trim()) ?? 0) : 0,
      'notes': _notesCtrl.text.trim(),
      'pointsEarned': int.tryParse(_pointsCtrl.text) ?? 0,
      'status': _status,
      'studentId': _selectedStudent,
      'surah': _showRecitationFields ? _surahCtrl.text.trim() : "",
      'timestamp': FieldValue.serverTimestamp(),
      'tomorrowRequirement': _tomorrowCtrl.text.trim(),
    };

    await service.addRecord(data);

    if (_status == 'حاضر') {
      await FirebaseFirestore.instance.collection('students').doc(_selectedStudent).update({
        'totalPoints': FieldValue.increment(data['pointsEarned'] as int),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح ✅')));
    }

    // إعادة ضبط الحقول بعد الحفظ
    _surahCtrl.clear();
    _fromCtrl.clear();
    _toCtrl.clear();
    _linesCountCtrl.clear();
    _tomorrowCtrl.clear();
    _notesCtrl.clear();
    _pointsCtrl.text = '10';
    setState(() => _evaluations.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رصد التسميع')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedHalaqa,
              items: _halaqat
                  .map<DropdownMenuItem<String>>(
                    (h) => DropdownMenuItem<String>(
                      value: h['id'] as String,
                      child: Text(h['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedHalaqa = v;
                  _selectedStudent = null;
                });
                if (v != null) _loadStudents(v);
              },
              decoration: const InputDecoration(labelText: 'الحلقة'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStudent,
              items: _students
                  .map<DropdownMenuItem<String>>(
                    (s) => DropdownMenuItem<String>(
                      value: s['id'] as String,
                      child: Text(s['name'] as String),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedStudent = v),
              decoration: const InputDecoration(labelText: 'الطالب'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem<String>(value: 'حاضر', child: Text('✅ حاضر')),
                DropdownMenuItem<String>(value: 'غائب', child: Text('❌ غائب')),
                DropdownMenuItem<String>(value: 'إجازة', child: Text('🔵 إجازة')),
              ],
              onChanged: (v) {
                setState(() {
                  _status = v!;
                  _showRecitationFields = v == 'حاضر';
                  _pointsCtrl.text = _showRecitationFields ? '10' : '0';
                });
              },
              decoration: const InputDecoration(labelText: 'الحالة'),
            ),
            if (_showRecitationFields) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _surahCtrl,
                decoration: const InputDecoration(labelText: 'اسم السورة (مثال: الفلق)'),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'من آية'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _toCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'إلى آية'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _linesCountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'عدد الأسطر'),
              ),
              const SizedBox(height: 12),
              Text('تقييم الأداء:', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                children: ['إتقان', 'حفظ', 'تجويد'].map(
                  (e) => FilterChip(
                    label: Text(e),
                    selected: _evaluations.contains(e),
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _evaluations.add(e);
                        } else {
                          _evaluations.remove(e);
                        }
                      });
                    },
                  ),
                ).toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pointsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'النقاط المكتسبة'),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _tomorrowCtrl,
              decoration: const InputDecoration(labelText: 'المطلوب غداً (مثال: الكوثر)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات المدرس'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('📤 إرسال التحديث', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

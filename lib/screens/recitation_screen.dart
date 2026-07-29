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
  final _tomorrowCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '10');

  String _status = 'حاضر';
  final List<String> _evaluations = [];
  bool _showRecitationFields = true;

  List<Map<String, dynamic>> _halaqat = [];
  List<Map<String, dynamic>> _students = [];
  bool _isLoadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadHalaqat();
  }

  @override
  void dispose() {
    _surahCtrl.dispose();
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _tomorrowCtrl.dispose();
    _notesCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  // 1. تحميل قائمة الحلقات
  Future<void> _loadHalaqat() async {
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final list = await service.loadHalaqatList();

      setState(() {
        _halaqat = list.map((h) => {
          'id': h.id,
          'name': h.name,
          'teacherName': h.teacherName,
          'teacherPhone': h.teacherPhone ?? "967770000000",
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل الحلقات: $e');
    }
  }

  // 2. تحميل طلاب الحلقة المحددة
  Future<void> _loadStudents(String halaqaId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final list = await service.loadStudentsByHalaqa(halaqaId);

      setState(() {
        _students = list.map((s) => {
          'id': s.id,
          'name': s.name,
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل الطلاب: $e');
    } finally {
      setState(() => _isLoadingStudents = false);
    }
  }

  // 3. حفظ التسميع بنفس طريقة الـ JavaScript تماماً
  Future<void> _save() async {
    if (_selectedHalaqa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الحلقة')),
      );
      return;
    }

    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الطالب')),
      );
      return;
    }

    final String surah = _surahCtrl.text.trim();
    final String fromAya = _fromCtrl.text.trim();
    final String toAya = _toCtrl.text.trim();
    final String tomorrowReq = _tomorrowCtrl.text.trim();
    final String notes = _notesCtrl.text.trim();
    final int points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;

    if (_status == 'حاضر' && surah.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم السورة')),
      );
      return;
    }

    // 🎯 حساب grade بنفس منطق الـ JS
    final String grade = _evaluations.isNotEmpty
        ? _evaluations.first
        : (_status == 'حاضر' ? 'جيد' : '-');

    // 🎯 جلب رقم المعلم
    final selectedHalaqaData = _halaqat.firstWhere(
      (h) => h['id'] == _selectedHalaqa,
      orElse: () => {'teacherPhone': '967770000000'},
    );
    final String teacherPhone = selectedHalaqaData['teacherPhone'] ?? "967770000000";

    try {
      final Map<String, dynamic> recordData = {
        'studentId': _selectedStudent,
        'status': _status,
        'surah': _status == 'حاضر' ? surah : _status,
        'fromAyah': fromAya.isNotEmpty ? fromAya : "0",
        'toAyah': toAya.isNotEmpty ? toAya : "0",
        'grade': grade,
        'tomorrowRequirement': tomorrowReq.isNotEmpty ? tomorrowReq : "لا يوجد",
        'notes': notes,
        'teacherPhone': teacherPhone,
        'pointsGiven': points,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
      };

      // الحفظ في كولكشن records
      await FirebaseFirestore.instance.collection('records').add(recordData);

      // زيادة النقاط للطالب عند الحضور
      if (_status == 'حاضر' && points > 0) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(_selectedStudent)
            .update({
          'totalPoints': FieldValue.increment(points),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ تم تحديث سجل الطالب\n📊 النقاط: $points')),
        );
      }

      // تصفير الحقول
      _surahCtrl.clear();
      _fromCtrl.clear();
      _toCtrl.clear();
      _tomorrowCtrl.clear();
      _notesCtrl.clear();
      _pointsCtrl.text = _status == 'حاضر' ? '10' : '0';
      setState(() {
        _evaluations.clear();
      });
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ أثناء الحفظ: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رصد التسميع')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // اختيار الحلقة
            DropdownButtonFormField<String>(
              value: _selectedHalaqa,
              decoration: const InputDecoration(labelText: 'اختر الحلقة...'),
              items: _halaqat.map((h) {
                return DropdownMenuItem<String>(
                  value: h['id'] as String,
                  child: Text("${h['name']} - (الشيخ: ${h['teacherName']})"),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedHalaqa = val;
                  _selectedStudent = null;
                  _students.clear();
                });
                if (val != null) _loadStudents(val);
              },
            ),
            const SizedBox(height: 12),

            // اختيار الطالب
            DropdownButtonFormField<String>(
              value: _selectedStudent,
              decoration: InputDecoration(
                labelText: 'اختر الطالب...',
                suffixIcon: _isLoadingStudents
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _students.map((s) {
                return DropdownMenuItem<String>(
                  value: s['id'] as String,
                  child: Text(s['name'] as String),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedStudent = val);
              },
            ),
            const SizedBox(height: 16),

            // الحالة
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'الحالة'),
              items: const [
                DropdownMenuItem(value: 'حاضر', child: Text('حاضر')),
                DropdownMenuItem(value: 'غائب', child: Text('غائب')),
                DropdownMenuItem(value: 'إجازة', child: Text('إجازة')),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _status = val;
                  _showRecitationFields = val == 'حاضر';
                  _pointsCtrl.text = val == 'حاضر' ? '10' : '0';
                });
              },
            ),

            // حقول التسميع (عند الحضور فقط)
            if (_showRecitationFields) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _surahCtrl,
                decoration: const InputDecoration(labelText: 'السورة الحالية'),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              const Text('التقييم:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8.0,
                children: ['إتقان', 'حفظ', 'تجويد', 'ممتاز', 'جيد جداً', 'جيد'].map((e) {
                  return FilterChip(
                    label: Text(e),
                    selected: _evaluations.contains(e),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _evaluations.add(e);
                        } else {
                          _evaluations.remove(e);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),
            TextField(
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'النقاط الممنوحة'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tomorrowCtrl,
              decoration: const InputDecoration(labelText: 'المطلوب غداً'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'ملاحظات المعلم'),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('حفظ السجل', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

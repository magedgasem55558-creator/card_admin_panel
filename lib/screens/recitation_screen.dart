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

  bool _isLoadingHalaqat = false;
  bool _isLoadingStudents = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHalaqat();
    });
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

  // 1. تحميل الحلقات
  Future<void> _loadHalaqat() async {
    setState(() => _isLoadingHalaqat = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final list = await service.loadHalaqatList();

      setState(() {
        _halaqat = list.map((h) => {
          'id': h.id,
          'name': h.name ?? 'حلقة بدون اسم',
          'teacherName': h.teacherName ?? 'غير محدد',
          'teacherPhone': h.teacherPhone ?? "967770000000",
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل الحلقات: $e');
      _showSnackBar('حدث خطأ أثناء تحميل الحلقات: $e');
    } finally {
      if (mounted) setState(() => _isLoadingHalaqat = false);
    }
  }

  // 2. تحميل الطلاب
  Future<void> _loadStudents(String halaqaId) async {
    setState(() => _isLoadingStudents = true);
    try {
      final service = Provider.of<FirestoreService>(context, listen: false);
      final list = await service.loadStudentsByHalaqa(halaqaId);

      setState(() {
        _students = list.map((s) => {
          'id': s.id,
          'name': s.name ?? 'طالب بدون اسم',
        }).toList();
      });
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحميل الطلاب: $e');
      _showSnackBar('حدث خطأ أثناء تحميل الطلاب: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // 3. دالة الحفظ المطابقة لـ JavaScript 100%
  Future<void> _save() async {
    final String? studentId = _selectedStudent;
    final String? halaqaId = _selectedHalaqa;
    final String status = _status;

    // if (!studentId || !halaqaId) return alert("يرجى اختيار الحلقة والطالب");
    if (studentId == null || studentId.isEmpty || halaqaId == null || halaqaId.isEmpty) {
      _showSnackBar('يرجى اختيار الحلقة والطالب');
      return;
    }

    final String surah = _surahCtrl.text.trim();
    final String fromAya = _fromCtrl.text;
    final String toAya = _toCtrl.text;
    final String tomorrowReq = _tomorrowCtrl.text.trim();
    final String notes = _notesCtrl.text.trim();
    final int points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;

    // if (status === "حاضر" && !surah) return alert("يرجى إدخال اسم السورة");
    if (status == 'حاضر' && surah.isEmpty) {
      _showSnackBar('يرجى إدخال اسم السورة');
      return;
    }

    setState(() => _isSaving = true);

    // const grade = evaluations.length > 0 ? evaluations.join(" - ") : (status === "حاضر" ? "جيد" : "-");
    final String grade = _evaluations.isNotEmpty
        ? _evaluations.join(" - ")
        : (status == 'حاضر' ? 'جيد' : '-');

    // let teacherPhone = "967770000000";
    String teacherPhone = "967770000000";
    final selectedHalaqaData = _halaqat.firstWhere(
      (h) => h['id'] == halaqaId,
      orElse: () => {'teacherPhone': '967770000000'},
    );
    if (selectedHalaqaData['teacherPhone'] != null) {
      teacherPhone = selectedHalaqaData['teacherPhone'];
    }

    try {
      // await addDoc(collection(db, "records"), { ... });
      await FirebaseFirestore.instance.collection('records').add({
        'studentId': studentId,
        'status': status,
        'surah': status == 'حاضر' ? surah : status,
        'fromAyah': fromAya.isNotEmpty ? fromAya : "0",
        'toAyah': toAya.isNotEmpty ? toAya : "0",
        'grade': grade,
        'tomorrowRequirement': tomorrowReq.isNotEmpty ? tomorrowReq : "لا يوجد",
        'notes': notes,
        'teacherPhone': teacherPhone,
        'pointsGiven': points,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'timestamp': FieldValue.serverTimestamp(),
      });

      // if (status === "حاضر" && points > 0) { ... }
      if (status == 'حاضر' && points > 0) {
        await FirebaseFirestore.instance
            .collection('students')
            .doc(studentId)
            .update({
          'totalPoints': FieldValue.increment(points),
        });
      }

      _showSnackBar('✅ تم تحديث سجل الطالب\n📊 النقاط: $points');

      // إعادة تصفير العناصر كود الـ JS
      _surahCtrl.clear();
      _fromCtrl.clear();
      _toCtrl.clear();
      _tomorrowCtrl.clear();
      _notesCtrl.clear();
      _pointsCtrl.text = status == 'حاضر' ? '10' : '0';
      setState(() {
        _evaluations.clear();
      });

    } catch (e) {
      debugPrint('❌ error: $e');
      _showSnackBar('خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
              decoration: InputDecoration(
                labelText: 'اختر الحلقة...',
                suffixIcon: _isLoadingHalaqat
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              items: _halaqat.map((h) {
                return DropdownMenuItem<String>(
                  value: h['id'] as String,
                  child: Text("${h['name']} - (الشيخ: ${h['teacherName']})"),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _selectedHalaqa = val;
                  _selectedStudent = null;
                  _students.clear();
                });
                _loadStudents(val);
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

            // حقول التسميع (عند الحضور)
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
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('حفظ السجل', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

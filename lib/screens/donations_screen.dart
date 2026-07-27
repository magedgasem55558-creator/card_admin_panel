import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class DonationsScreen extends StatefulWidget {
  const DonationsScreen({super.key});
  @override
  State<DonationsScreen> createState() => _DonationsScreenState();
}

class _DonationsScreenState extends State<DonationsScreen> {
  final _bankCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _transferCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _hadithCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    final data = await service.loadDonationInfo();
    if (data != null) {
      _bankCtrl.text = data['bankName'] ?? '';
      _accountCtrl.text = data['accountNumber'] ?? '';
      _transferCtrl.text = data['transferName'] ?? '';
      _phoneCtrl.text = data['phone'] ?? '';
      _hadithCtrl.text = data['hadith'] ?? '';
      setState(() {});
    }
  }

  Future<void> _save() async {
    final service = Provider.of<FirestoreService>(context, listen: false);
    await service.updateDonationInfo({
      'bankName': _bankCtrl.text.trim(),
      'accountNumber': _accountCtrl.text.trim(),
      'transferName': _transferCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'hadith': _hadithCtrl.text.trim(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات التبرعات ✅')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة التبرعات')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(controller: _bankCtrl, decoration: const InputDecoration(labelText: 'اسم البنك')),
            const SizedBox(height: 12),
            TextField(controller: _accountCtrl, decoration: const InputDecoration(labelText: 'رقم الحساب')),
            const SizedBox(height: 12),
            TextField(controller: _transferCtrl, decoration: const InputDecoration(labelText: 'اسم المستفيد')),
            const SizedBox(height: 12),
            TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'رقم التواصل')),
            const SizedBox(height: 12),
            TextField(controller: _hadithCtrl, decoration: const InputDecoration(labelText: 'حديث أو آية'), maxLines: 3),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('💾 حفظ البيانات')),
          ],
        ),
      ),
    );
  }
}
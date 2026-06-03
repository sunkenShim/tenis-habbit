import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TermsScreen extends StatefulWidget {
  final VoidCallback onAgreed;

  const TermsScreen({super.key, required this.onAgreed});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;
  bool _isLoading = false;

  bool get _canProceed => _agreedToTerms && _agreedToPrivacy;

  Future<void> _saveAgreement() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'hasAgreedToTerms': true,
        'termsAgreedAt': FieldValue.serverTimestamp(),
        // 기본 프로필 필드 초기화
        'createdAt': FieldValue.serverTimestamp(),
        'displayName': FirebaseAuth.instance.currentUser!.displayName ?? '테니스의길',
        'isPremium': false,
      }, SetOptions(merge: true));

      widget.onAgreed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('동의 내역 저장 실패: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '환영합니다!\n서비스 이용을 위해\n약관에 동의해 주세요.',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.4),
            ),
            const SizedBox(height: 40),
            _buildAgreementRow(
              title: '(필수) 서비스 이용약관 동의',
              value: _agreedToTerms,
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
              onTapDetail: () => _showTextDialog('서비스 이용약관', '여기에 서비스 이용약관 전문이 들어갑니다.'),
            ),
            const SizedBox(height: 16),
            _buildAgreementRow(
              title: '(필수) 개인정보 처리방침 동의',
              value: _agreedToPrivacy,
              onChanged: (val) => setState(() => _agreedToPrivacy = val ?? false),
              onTapDetail: () => _showTextDialog('개인정보 처리방침', '여기에 개인정보 처리방침 전문이 들어갑니다.'),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _saveAgreement : null,
                  child: const Text('동의하고 시작하기'),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAgreementRow({
    required String title,
    required bool value,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onTapDetail,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? Theme.of(context).colorScheme.primary : Colors.grey.shade800),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontSize: 14)),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Theme.of(context).colorScheme.primary,
        checkColor: Colors.black,
        secondary: TextButton(
          onPressed: onTapDetail,
          child: const Text('보기', style: TextStyle(fontSize: 12, decoration: TextDecoration.underline)),
        ),
      ),
    );
  }

  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }
}

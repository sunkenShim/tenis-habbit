import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChecklistManageScreen extends StatefulWidget {
  const ChecklistManageScreen({super.key});

  @override
  State<ChecklistManageScreen> createState() => _ChecklistManageScreenState();
}

class _ChecklistManageScreenState extends State<ChecklistManageScreen> {
  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트 관리'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('checklists')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('에러: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteItem(doc.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 항목 추가'),
        content: TextField(
          controller: _controller,
          decoration: const InputDecoration(hintText: '예: 스플릿 스텝 잘하기'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _addItem(_controller.text);
                _controller.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItem(String title) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('checklists')
        .add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('checklists')
        .doc(id)
        .delete();
  }
}

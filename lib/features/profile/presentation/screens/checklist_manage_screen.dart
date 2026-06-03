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

  static const List<String> _defaultItems = [
    '항상 스플릿 스텝',
    '항상 리커버리 스텝',
    '대근육으로 친다는 느낌!',
    '공만 보고 치기!!!! staying present',
    '왼팔 뻗어 눌러주기',
    '왼팔 내리지 말고 위로 접기',
    '유닛턴 빠르게 해서 라켓 미리 빼기',
    '타점 앞에서 치기 타이밍 늦지 않기',
    '앉았다 일어나는 느낌 갖기',
    '퍼올려 치지 말기',
    '라켓드롭할때 면 아래로 하기 4시->10시',
    '가속 구간 지키기',
    '공 4개 밀어서 지나가는 느낌 go through the ball. 공을 질기게 치는 느낌',
    '공이 떨어지기 기다리지 말고 공이 높을때 치기',
    '발리 손목쓰지 않기. 몸을 앞으로 밀기',
    '발리 준비 자세에서 라켓 뒤로 빼지 않기',
    '발리 턱 내리지 않기.',
    '서브 트로피 자세, 라켓 드롭',
    '서브 왼팔 올리기',
    '서브 내전',
    '서브때 라켓 각도 더 머리쪽으로 잡기',
    '백핸드 라켓 넘기기',
    '백핸드 라켓드롭',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('체크리스트 관리'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') _confirmReset();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('기본값으로 초기화'),
                  ],
                ),
              ),
            ],
          ),
        ],
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

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('체크리스트 항목이 없습니다.'),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _confirmReset,
                    icon: const Icon(Icons.refresh),
                    label: const Text('기본값 불러오기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditDialog(doc.id, data['title'] ?? ''),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteItem(doc.id),
                    ),
                  ],
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
    _controller.clear();
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
                _addItem(_controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String id, String currentTitle) {
    _controller.text = currentTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('항목 편집'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '내용을 수정하세요'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (_controller.text.isNotEmpty) {
                _editItem(id, _controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('기본값으로 초기화'),
        content: const Text('기존 항목을 모두 삭제하고 기본 체크리스트 23개를 불러올까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetToDefaults();
            },
            child: const Text('초기화', style: TextStyle(color: Colors.red)),
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

  Future<void> _editItem(String id, String newTitle) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('checklists')
        .doc(id)
        .update({'title': newTitle});
  }

  Future<void> _deleteItem(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('checklists')
        .doc(id)
        .delete();
  }

  Future<void> _resetToDefaults() async {
    final collectionRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUserId)
        .collection('checklists');

    final existing = await collectionRef.get();
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    final now = Timestamp.now();
    for (int i = 0; i < _defaultItems.length; i++) {
      final newDoc = collectionRef.doc();
      batch.set(newDoc, {
        'title': _defaultItems[i],
        'createdAt': Timestamp(now.seconds + i, now.nanoseconds),
      });
    }

    await batch.commit();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('기본 체크리스트로 초기화했습니다.')),
      );
    }
  }
}

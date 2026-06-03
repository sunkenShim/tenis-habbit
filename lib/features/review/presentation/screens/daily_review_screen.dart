import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';
import 'package:tennis_habit/features/review/presentation/widgets/share_card_widget.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  final String _testUserId = 'test_user_id';
  final DateTime _selectedDate = DateTime.now();

  List<String> _selectedTags = [];
  int _conditionScore = 3;
  Map<String, int> _scores = {};
  final TextEditingController _feedbackController = TextEditingController();

  final List<String> _availableTags = ['연습', '레슨', '단식', '복식', '하드코트', '클레이코트', '잔디코트'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChecklistsAndTodayLog();
  }

  Future<void> _fetchChecklistsAndTodayLog() async {
    setState(() => _isLoading = true);
    
    // 1. Fetch custom checklists
    final checklistSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_testUserId)
        .collection('checklists')
        .orderBy('createdAt', descending: false)
        .get();

    final List<String> checklistTitles = checklistSnapshot.docs
        .map((doc) => doc.data()['title'] as String)
        .toList();

    // Default items if none exist
    if (checklistTitles.isEmpty) {
      checklistTitles.addAll(['스플릿 스텝 잘하기', '공 4개 통과하는 느낌으로 치기', '라켓 끝까지 던지기']);
    }

    // 2. Fetch today's log if exists
    final logId = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    final logDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_testUserId)
        .collection('tennis_logs')
        .doc(logId)
        .get();

    Map<String, int> initialScores = {for (var title in checklistTitles) title: 2};
    List<String> initialTags = [];
    int initialCondition = 3;
    String initialFeedback = '';

    if (logDoc.exists) {
      final log = TennisLogModel.fromMap(logDoc.data()!, logDoc.id);
      initialTags = log.sessionTags;
      initialCondition = log.conditionScore;
      initialFeedback = log.feedbackText;
      // Merge existing scores with checklist (in case checklist items changed)
      for (var title in checklistTitles) {
        if (log.scores.containsKey(title)) {
          initialScores[title] = log.scores[title]!;
        }
      }
    }

    setState(() {
      _scores = initialScores;
      _selectedTags = initialTags;
      _conditionScore = initialCondition;
      _feedbackController.text = initialFeedback;
      _isLoading = false;
    });
  }

  Future<void> _saveLog() async {
    final log = TennisLogModel(
      date: _selectedDate,
      sessionTags: _selectedTags,
      conditionScore: _conditionScore,
      scores: _scores,
      feedbackText: _feedbackController.text,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_testUserId)
          .collection('tennis_logs')
          .doc(log.documentId)
          .set(log.toMap(), SetOptions(merge: true));

      if (mounted) {
        _showShareDialog(log);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  void _showShareDialog(TennisLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: ShareCardWidget(log: log),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _onTagSelected(String tag, bool selected) {
    HapticFeedback.lightImpact();
    setState(() {
      if (selected) {
        _selectedTags.add(tag);
      } else {
        _selectedTags.remove(tag);
      }
    });
  }

  void _onScoreChanged(String criteria, int score) {
    HapticFeedback.lightImpact();
    setState(() {
      _scores[criteria] = score;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 테니스 회고'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveLog,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('세션 태그', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _availableTags.map((tag) {
                    return ChoiceChip(
                      label: Text(tag),
                      selected: _selectedTags.contains(tag),
                      onSelected: (selected) => _onTagSelected(tag, selected),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text('오늘의 컨디션', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Slider(
                  value: _conditionScore.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _conditionScore.toString(),
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _conditionScore = value.round();
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('핵심 체크리스트', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: _fetchChecklistsAndTodayLog,
                      child: const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._scores.keys.map((criteria) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(criteria, style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ScoreButton(
                              emoji: '😥',
                              label: '아쉬움',
                              isSelected: _scores[criteria] == 1,
                              onTap: () => _onScoreChanged(criteria, 1),
                            ),
                            _ScoreButton(
                              emoji: '😐',
                              label: '보통',
                              isSelected: _scores[criteria] == 2,
                              onTap: () => _onScoreChanged(criteria, 2),
                            ),
                            _ScoreButton(
                              emoji: '🔥',
                              label: '완벽함',
                              isSelected: _scores[criteria] == 3,
                              onTap: () => _onScoreChanged(criteria, 3),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 24),
                const Text('오늘의 깨달음 한 줄', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _feedbackController,
                  decoration: const InputDecoration(
                    hintText: '예: 오늘은 백핸드 시선을 끝까지 고정했다.',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ScoreButton({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Theme.of(context).primaryColor : Colors.black54,
            )),
          ],
        ),
      ),
    );
  }
}

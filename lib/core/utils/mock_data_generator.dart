import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/review/domain/models/tennis_log_model.dart';

class MockDataGenerator {
  static final List<String> _tags = ['연습', '레슨', '단식', '복식', '하드코트', '클레이코트'];
  static final List<String> _feedbacks = [
    '오늘은 서브가 아주 잘 들어갔다.',
    '포핸드 스트로크 시 라켓 면이 너무 닫히는 것 같다.',
    '스플릿 스텝을 의식하니 발이 빨라졌다.',
    '백핸드 슬라이스 연습이 더 필요하다.',
    '발리 시 손목 고정에 집중했다.',
  ];

  static Future<void> generate14DaysLogs(String userId) async {
    final firestore = FirebaseFirestore.instance;
    final random = Random();
    final now = DateTime.now();

    for (int i = 0; i < 14; i++) {
      final date = now.subtract(Duration(days: i));
      final log = TennisLogModel(
        date: date,
        sessionTags: (_tags..shuffle()).take(random.nextInt(3) + 1).toList(),
        conditionScore: random.nextInt(5) + 1,
        scores: {
          '스플릿 스텝 잘하기': random.nextInt(3) + 1,
          '공 4개 통과하는 느낌으로 치기': random.nextInt(3) + 1,
          '라켓 끝까지 던지기': random.nextInt(3) + 1,
        },
        feedbackText: _feedbacks[random.nextInt(_feedbacks.length)],
      );

      await firestore
          .collection('users')
          .doc(userId)
          .collection('tennis_logs')
          .doc(log.documentId)
          .set(log.toMap());
    }
  }
}

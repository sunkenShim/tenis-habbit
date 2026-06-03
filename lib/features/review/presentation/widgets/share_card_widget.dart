import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:tennis_habit/features/review/domain/models/tennis_log_model.dart';

class ShareCardWidget extends StatelessWidget {
  final TennisLogModel log;

  const ShareCardWidget({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green.shade700,
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1595435934249-5df7ed86e1c0?auto=format&fit=crop&q=80&w=400'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TENNIS HABIT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              Text(
                DateFormat('MM.dd').format(log.date),
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 40),
          const Text(
            '오늘의 깨달음',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            log.feedbackText.isEmpty ? '오늘도 한 걸음 성장했습니다!' : log.feedbackText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              _buildStat('컨디션', '${log.conditionScore}점'),
              const SizedBox(width: 24),
              _buildStat('평가', _getOverallGrade()),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final text = '🎾 오늘의 테니스 회고\n\n"${log.feedbackText}"\n\n#테니스해빗 #오운완 #테니스';
              Share.share(text);
            },
            icon: const Icon(Icons.share),
            label: const Text('오운완 공유하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade700,
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _getOverallGrade() {
    double avg = log.scores.values.fold(0, (a, b) => a + b) / log.scores.length;
    if (avg >= 2.5) return '🔥 완벽함';
    if (avg >= 1.5) return '😐 보통';
    return '😥 아쉬움';
  }
}

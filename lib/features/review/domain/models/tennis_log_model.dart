import 'package:cloud_firestore/cloud_firestore.dart';

class TennisLogModel {
  final DateTime date;
  final List<String> sessionTags;
  final int conditionScore;
  final Map<String, int> scores;
  final String feedbackText;

  TennisLogModel({
    required this.date,
    required this.sessionTags,
    required this.conditionScore,
    required this.scores,
    required this.feedbackText,
  });

  String get documentId =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'sessionTags': sessionTags,
      'conditionScore': conditionScore,
      'scores': scores,
      'feedbackText': feedbackText,
    };
  }

  factory TennisLogModel.fromMap(Map<String, dynamic> map, String id) {
    return TennisLogModel(
      date: (map['date'] as Timestamp).toDate(),
      sessionTags: List<String>.from(map['sessionTags'] ?? []),
      conditionScore: map['conditionScore'] ?? 3,
      scores: Map<String, int>.from(map['scores'] ?? {}),
      feedbackText: map['feedbackText'] ?? '',
    );
  }
}

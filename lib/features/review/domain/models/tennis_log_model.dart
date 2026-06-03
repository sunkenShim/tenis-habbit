import 'package:cloud_firestore/cloud_firestore.dart';

class TennisLogModel {
  final DateTime date;
  final List<String> matchTypes;
  final String courtSurface;
  final int conditionScore;
  final Map<String, int> scores;
  final String feedbackText;

  TennisLogModel({
    required this.date,
    required this.matchTypes,
    required this.courtSurface,
    required this.conditionScore,
    required this.scores,
    required this.feedbackText,
  });

  String get documentId =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'matchTypes': matchTypes,
      'courtSurface': courtSurface,
      'conditionScore': conditionScore,
      'scores': scores,
      'feedbackText': feedbackText,
    };
  }

  factory TennisLogModel.fromMap(Map<String, dynamic> map, String id) {
    // Backwards compatibility with old 'sessionTags'
    List<String> oldTags = List<String>.from(map['sessionTags'] ?? []);
    List<String> mTypes = List<String>.from(map['matchTypes'] ?? []);
    String cSurface = map['courtSurface'] ?? '';

    if (oldTags.isNotEmpty && mTypes.isEmpty) {
      final courts = ['하드코트', '클레이코트', '잔디코트'];
      for (var tag in oldTags) {
        if (courts.contains(tag)) {
          cSurface = tag;
        } else {
          mTypes.add(tag);
        }
      }
    }

    return TennisLogModel(
      date: (map['date'] as Timestamp).toDate(),
      matchTypes: mTypes,
      courtSurface: cSurface.isEmpty ? '하드코트' : cSurface, // default
      conditionScore: map['conditionScore'] ?? 3,
      scores: Map<String, int>.from(map['scores'] ?? {}),
      feedbackText: map['feedbackText'] ?? '',
    );
  }
}

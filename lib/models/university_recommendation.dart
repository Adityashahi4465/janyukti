import 'university_model.dart';

class UniversityRecommendation {
  const UniversityRecommendation({
    required this.university,
    required this.score,
    required this.reasons,
  });

  final UniversityModel university;

  /// 0.0 - 1.0
  final double score;

  final List<String> reasons;

  int get percentage =>
      (score * 100).round();
}
import 'package:flutter/material.dart';

import '../../../models/university_recommendation.dart';
import '../../../theme/app_colors.dart';

// ============================================================
// BEST UNIVERSITY CARD
// ============================================================

class BestUniversityCard extends StatelessWidget {
  const BestUniversityCard({super.key, required this.recommendation});

  final UniversityRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final university = recommendation.university;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.green.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // BEST MATCH + SCORE
          // ======================================================
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'BEST MATCH',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                '${recommendation.percentage}% match',
                style: TextStyle(
                  color: universityScoreColor(recommendation.score),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ======================================================
          // UNIVERSITY
          // ======================================================
          Text(
            university.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.title,
            ),
          ),

          if (university.city.trim().isNotEmpty ||
              university.state.trim().isNotEmpty) ...[
            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    [
                      university.city,
                      university.state,
                    ].where((value) => value.trim().isNotEmpty).join(', '),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ======================================================
          // UNIVERSITY TYPE
          // ======================================================
          if (university.type.trim().isNotEmpty) ...[
            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    university.type,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ======================================================
          // MATCH REASONS
          // ======================================================
          if (recommendation.reasons.isNotEmpty) ...[
            const SizedBox(height: 12),

            for (final reason in recommendation.reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: Colors.green,
                    ),

                    const SizedBox(width: 6),

                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 8),

          // ======================================================
          // CANONICAL ID / ML STATUS
          // ======================================================
          Row(
            children: [
              Text(
                university.id,
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
              ),

              const Spacer(),

              if (university.mlEligible)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ML ELIGIBLE',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SELECTED UNIVERSITY INFO
// PUBLIC because ChallengeReview uses this widget.
// ============================================================

class SelectedUniversityInfo extends StatelessWidget {
  const SelectedUniversityInfo({super.key, required this.recommendation});

  final UniversityRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final university = recommendation.university;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7EBF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.admin.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: AppColors.admin,
              size: 20,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  university.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${recommendation.percentage}% relevance score',
                  style: TextStyle(
                    color: universityScoreColor(recommendation.score),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                if (university.city.trim().isNotEmpty ||
                    university.state.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),

                  Text(
                    [
                      university.city,
                      university.state,
                    ].where((value) => value.trim().isNotEmpty).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'University ID',
                style: TextStyle(color: AppColors.muted, fontSize: 8.5),
              ),

              const SizedBox(height: 2),

              Text(
                university.id,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SCORE COLOR
// PUBLIC because ChallengeReview dropdown uses this.
// ============================================================

Color universityScoreColor(double score) {
  if (score >= .75) {
    return Colors.green;
  }

  if (score >= .50) {
    return Colors.orange;
  }

  return AppColors.muted;
}

import '../widgets/challange_card.dart';
import '../widgets/matric_card.dart';
import '../widgets/section_header.dart';
import '../widgets/status_card.dart';
import 'registration_approvals_view.dart';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/mock_data/app_store.dart';
import '../../../widgets/ui.dart';
import '../../../theme/app_colors.dart';
import '../../auth/services/auth_session.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final challenges = store.challenges;

    // Replace these with actual values from StoreScope when available.
    const universityCount = 0;
    const industryCount = 0;
    const pendingRequestCount = 1;

    final underReviewCount = challenges.isEmpty
        ? 0
        : (challenges.length * .4).ceil();

    final assignedCount = challenges.isEmpty
        ? 0
        : (challenges.length * .2).ceil();

    final resolvedCount = challenges.length - underReviewCount - assignedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FE),
      body: SafeArea(
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // HEADER
            // ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101B42),
                            letterSpacing: -0.7,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Manage challenges, registrations and more',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.admin.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          color: AppColors.admin,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  IconButton(
                    tooltip: 'Logout',
                    onPressed: () => AuthSession.signOut(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF27332D),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────────
            // BODY
            // ─────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                children: [
                  // Overview
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Overview',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF101B42),
                          ),
                        ),
                      ),
                      Text(
                        _dashboardDate(DateTime.now()),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.85,
                    children: [
                      MetricCard(
                        count: challenges.length,
                        label: 'Challenges',
                        icon: Icons.description_rounded,
                        color: AppColors.admin,
                      ),
                      const MetricCard(
                        count: universityCount,
                        label: 'Universities',
                        icon: Icons.school_rounded,
                        color: Color(0xFF8A4DE8),
                      ),
                      const MetricCard(
                        count: industryCount,
                        label: 'Industries',
                        icon: Icons.apartment_rounded,
                        color: Color(0xFF16A779),
                      ),
                      const MetricCard(
                        count: pendingRequestCount,
                        label: 'Pending Request',
                        icon: Icons.groups_rounded,
                        color: Color(0xFFF59E0B),
                        highlighted: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Registration Requests
                  SectionHeader(
                    title: 'Registration Requests ($pendingRequestCount)',
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegistrationApprovalsView(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  /*
                    Keep your existing registration component here.

                    I would recommend removing its own outer
                    "Pending Registration Requests" heading,
                    because we now provide the heading above.
                  */
                  const RegistrationApprovalsPreview(),

                  const SizedBox(height: 28),

                  // Challenge Status
                  SectionHeader(
                    title: 'Challenge Status',
                    onViewAll: () {
                      Navigator.pushNamed(context, Routes.analytics);
                    },
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: StatusCard(
                          count: underReviewCount,
                          label: 'Under Review',
                          icon: Icons.schedule_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatusCard(
                          count: assignedCount,
                          label: 'Assigned',
                          icon: Icons.group_rounded,
                          color: AppColors.admin,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatusCard(
                          count: resolvedCount,
                          label: 'Resolved',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10A875),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Recent challenges
                  SectionHeader(
                    title: 'Recent Challenges',
                    onViewAll: () {
                      Navigator.pushNamed(context, Routes.analytics);
                    },
                  ),

                  const SizedBox(height: 12),

                  ...List.generate(challenges.length, (index) {
                    final challenge = challenges[index];

                    final display = _challengeDisplay(index);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: ChallengeCard(
                        challenge: challenge,
                        status: display.status,
                        statusColor: display.color,
                        icon: display.icon,
                        iconColor: display.iconColor,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            Routes.review,
                            arguments: challenge,
                          );
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Analytics
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.analytics);
                      },
                      icon: Icon(
                        Icons.analytics_outlined,
                        color: AppColors.admin,
                      ),
                      label: Text(
                        'Analytics Dashboard',
                        style: TextStyle(
                          color: AppColors.admin,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: AppColors.admin.withOpacity(.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _dashboardDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${days[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static ChallengeDisplay _challengeDisplay(int index) {
    switch (index % 4) {
      case 0:
        return const ChallengeDisplay(
          status: 'Under Review',
          color: Color(0xFFF59E0B),
          icon: Icons.water_drop_rounded,
          iconColor: Color(0xFF16A6E5),
        );

      case 1:
        return ChallengeDisplay(
          status: 'Assigned',
          color: AppColors.admin,
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF0A9F6E),
        );

      case 2:
        return const ChallengeDisplay(
          status: 'Resolved',
          color: Color(0xFF10A875),
          icon: Icons.bolt_rounded,
          iconColor: Color(0xFF8155DB),
        );

      default:
        return const ChallengeDisplay(
          status: 'Under Review',
          color: Color(0xFFF59E0B),
          icon: Icons.menu_book_rounded,
          iconColor: Color(0xFFD63362),
        );
    }
  }
}

// class AdminDashboard extends StatelessWidget {
//   const AdminDashboard({super.key});
//   @override
//   Widget build(BuildContext c) {
//     final s = StoreScope.of(c);
//     return PageFrame(
//       title: 'Admin Dashboard',
//       color: AppColors.admin,
//       actions: [
//         IconButton(
//           onPressed: () => AuthSession.signOut(c),
//           icon: const Icon(Icons.logout_outlined),
//         ),
//       ],
//       child: ListView(
//         padding: const EdgeInsets.all(18),
//         children: [
//           OrganizationOverview(challengeCount: s.challenges.length),
//           const RegistrationApprovalsPreview(),
//           section('Challenge status'),
//           AppCard(
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 _chart('Under Review', .25, AppColors.warning),
//                 _chart('Assigned', .45, AppColors.admin),
//                 _chart('Resolved', .7, AppColors.success),
//               ],
//             ),
//           ),
//           section('Recent challenges'),
//           ...s.challenges.map(
//             (x) => AppCard(
//               onTap: () => Navigator.pushNamed(c, Routes.review, arguments: x),
//               child: ListTile(
//                 contentPadding: EdgeInsets.zero,
//                 title: Text(
//                   x.title,
//                   style: const TextStyle(fontWeight: FontWeight.w800),
//                 ),
//                 subtitle: Text(x.location),
//                 trailing: const Icon(Icons.arrow_forward_ios, size: 15),
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           RoleButton(
//             label: 'Analytics Dashboard',
//             color: AppColors.admin,
//             onTap: () => Navigator.pushNamed(c, Routes.analytics),
//             icon: Icons.analytics,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _chart(String x, double h, Color c) => Column(
//     children: [
//       Container(
//         width: 38,
//         height: 88 * h,
//         decoration: BoxDecoration(
//           color: c,
//           borderRadius: BorderRadius.circular(8),
//         ),
//       ),
//       const SizedBox(height: 8),
//       Text(x, style: const TextStyle(fontSize: 10)),
//     ],
//   );
// }

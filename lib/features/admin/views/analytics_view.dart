import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_routes.dart';
import '../../../models/challenge_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../citizen/controllers/citizen_controller.dart';

class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView({super.key});

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> {
  final TextEditingController _searchController = TextEditingController();

  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _timeFilter = 'All Time';

  final List<String> _statusOptions = const [
    'All',
    'Submitted',
    'Under Review',
    'Assigned',
    'In Progress',
    'Solution Deployed',
    'Resolved',
  ];

  final List<String> _timeOptions = const [
    'All Time',
    'Last 7 Days',
    'Last 30 Days',
    'Last 90 Days',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(challengesProvider);

    return PageFrame(
      title: 'Analytics Dashboard',
      color: AppColors.admin,
      child: challengesAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return _ErrorState(
            message: error.toString().replaceFirst('Exception: ', ''),
            onRetry: () {
              ref.invalidate(challengesProvider);
            },
          );
        },
        data: (allChallenges) {
          final categories =
              <String>{
                'All',
                ...allChallenges
                    .map((challenge) => challenge.category.trim())
                    .where((category) => category.isNotEmpty),
              }.toList()..sort((a, b) {
                if (a == 'All') return -1;
                if (b == 'All') return 1;

                return a.compareTo(b);
              });

          final filteredChallenges = _applyFilters(allChallenges);

          final stats = _AnalyticsStats.from(filteredChallenges);

          final categoryStats = _categoryCounts(filteredChallenges);

          final last7Days = _lastSevenDaySeries(filteredChallenges);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(challengesProvider);

              await ref.read(challengesProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 38),
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                _AnalyticsHero(total: filteredChallenges.length),

                const SizedBox(height: 22),

                const SizedBox(height: 24),

                // ==================================================
                // OVERVIEW METRICS
                // ==================================================
                const _SectionTitle(
                  title: 'Overview',
                  subtitle: 'Analytics based on the current filters.',
                ),

                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.65,
                  children: [
                    _MetricCard(
                      count: stats.total,
                      label: 'Total Complaints',
                      icon: Icons.campaign_outlined,
                      color: AppColors.admin,
                    ),
                    _MetricCard(
                      count: stats.underReview,
                      label: 'Under Review',
                      icon: Icons.search_rounded,
                      color: Colors.orange,
                    ),
                    _MetricCard(
                      count: stats.active,
                      label: 'Active',
                      icon: Icons.engineering_outlined,
                      color: Colors.blue,
                    ),
                    _MetricCard(
                      count: stats.resolved,
                      label: 'Resolved',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==================================================
                // CHALLENGES OVER TIME
                // ==================================================
                const _SectionTitle(
                  title: 'Challenges Over Time',
                  subtitle: 'Complaint volume over the last seven days.',
                ),

                const SizedBox(height: 12),

                AppCard(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 180,
                        child: CustomPaint(
                          painter: _LinePainter(values: last7Days.values),
                          child: const SizedBox.expand(),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: List.generate(last7Days.labels.length, (
                          index,
                        ) {
                          return Expanded(
                            child: Text(
                              last7Days.labels[index],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.muted,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // TOP CATEGORIES
                // ==================================================
                const _SectionTitle(
                  title: 'Top Categories',
                  subtitle:
                      'Categories generating the most citizen complaints.',
                ),

                const SizedBox(height: 12),

                AppCard(
                  child: categoryStats.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No category data available.',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ),
                        )
                      : Column(
                          children: categoryStats
                              .take(5)
                              .map(
                                (entry) => _CategoryRow(
                                  name: entry.key,
                                  count: entry.value,
                                  total: filteredChallenges.length,
                                ),
                              )
                              .toList(),
                        ),
                ),

                const SizedBox(height: 28),

                // ==================================================
                // STATUS SUMMARY
                // ==================================================
                const _SectionTitle(
                  title: 'Status Summary',
                  subtitle:
                      'Current distribution of complaint workflow stages.',
                ),

                const SizedBox(height: 12),

                AppCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusSummaryChip(
                        label: 'Submitted',
                        count: stats.submitted,
                        color: const Color(0xFF667085),
                      ),
                      _StatusSummaryChip(
                        label: 'Under Review',
                        count: stats.underReview,
                        color: Colors.orange,
                      ),
                      _StatusSummaryChip(
                        label: 'Assigned',
                        count: stats.assigned,
                        color: AppColors.admin,
                      ),
                      _StatusSummaryChip(
                        label: 'In Progress',
                        count: stats.inProgress,
                        color: Colors.blue,
                      ),
                      _StatusSummaryChip(
                        label: 'Deployed',
                        count: stats.deployed,
                        color: Colors.deepPurple,
                      ),
                      _StatusSummaryChip(
                        label: 'Resolved',
                        count: stats.resolved,
                        color: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // ==================================================
                // FILTERS
                // ==================================================
                const _SectionTitle(
                  title: 'Filters',
                  subtitle: 'Search and filter complaints across the platform.',
                ),

                const SizedBox(height: 12),

                _buildFilters(categories),

                const SizedBox(height: 30),

                // ==================================================
                // ALL COMPLAINTS
                // ==================================================
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                        title: 'All Complaints',
                        subtitle:
                            'Browse complaints matching the selected filters.',
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.admin.withOpacity(.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${filteredChallenges.length}',
                        style: TextStyle(
                          color: AppColors.admin,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (filteredChallenges.isEmpty)
                  const _EmptyComplaints()
                else
                  ...filteredChallenges.map((challenge) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ComplaintCard(
                        challenge: challenge,
                        onTap: () => _openChallenge(challenge),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER UI
  // ============================================================

  Widget _buildFilters(List<String> categories) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'Search title, location, category, citizen...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();

                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: BorderSide(color: AppColors.admin),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isExpanded: true,
                  decoration: _dropdownDecoration(
                    'Status',
                    Icons.filter_alt_outlined,
                  ),
                  items: _statusOptions
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: categories.contains(_categoryFilter)
                      ? _categoryFilter
                      : 'All',
                  isExpanded: true,
                  decoration: _dropdownDecoration(
                    'Category',
                    Icons.category_outlined,
                  ),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _categoryFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<String>(
              initialValue: _timeFilter,
              decoration: _dropdownDecoration(
                'Time Period',
                Icons.calendar_month_outlined,
              ),
              items: _timeOptions
                  .map(
                    (time) => DropdownMenuItem(value: time, child: Text(time)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }

                setState(() {
                  _timeFilter = value;
                });
              },
            ),
          ),

          if (_hasActiveFilters) ...[
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Clear Filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE1E7EF)),
      ),
    );
  }

  // ============================================================
  // FILTER LOGIC
  // ============================================================

  List<Challenge> _applyFilters(List<Challenge> challenges) {
    final search = _searchController.text.trim().toLowerCase();

    final now = DateTime.now();

    final result = challenges.where((challenge) {
      final status = challenge.status.trim().toLowerCase();

      // SEARCH
      if (search.isNotEmpty) {
        final matches =
            challenge.title.toLowerCase().contains(search) ||
            challenge.location.toLowerCase().contains(search) ||
            challenge.category.toLowerCase().contains(search) ||
            challenge.submittedBy.toLowerCase().contains(search) ||
            challenge.id.toLowerCase().contains(search);

        if (!matches) {
          return false;
        }
      }

      // STATUS
      if (_statusFilter != 'All') {
        final selected = _statusFilter.toLowerCase();

        if (selected == 'assigned') {
          if (!status.startsWith('assigned')) {
            return false;
          }
        } else if (selected == 'solution deployed') {
          if (status != 'solution deployed' && status != 'deployed') {
            return false;
          }
        } else if (selected == 'resolved') {
          if (status != 'resolved' && status != 'completed') {
            return false;
          }
        } else if (status != selected) {
          return false;
        }
      }

      // CATEGORY
      if (_categoryFilter != 'All' && challenge.category != _categoryFilter) {
        return false;
      }

      // TIME
      Duration? limit;

      switch (_timeFilter) {
        case 'Last 7 Days':
          limit = const Duration(days: 7);
          break;

        case 'Last 30 Days':
          limit = const Duration(days: 30);
          break;

        case 'Last 90 Days':
          limit = const Duration(days: 90);
          break;
      }

      if (limit != null) {
        if (now.difference(challenge.createdAt) > limit) {
          return false;
        }
      }

      return true;
    }).toList();

    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result;
  }

  bool get _hasActiveFilters {
    return _searchController.text.trim().isNotEmpty ||
        _statusFilter != 'All' ||
        _categoryFilter != 'All' ||
        _timeFilter != 'All Time';
  }

  void _clearFilters() {
    _searchController.clear();

    setState(() {
      _statusFilter = 'All';
      _categoryFilter = 'All';
      _timeFilter = 'All Time';
    });
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openChallenge(Challenge challenge) {
    final status = challenge.status.trim().toLowerCase();

    final hasAssignment =
        challenge.assignedUniversityId?.trim().isNotEmpty == true ||
        challenge.assignedUniversityName?.trim().isNotEmpty == true;

    final inMonitoring =
        hasAssignment ||
        status == 'assigned' ||
        status == 'in progress' ||
        status == 'solution deployed' ||
        status == 'deployed' ||
        status == 'resolved' ||
        status == 'completed';

    if (inMonitoring) {
      Navigator.pushNamed(context, Routes.monitoring, arguments: challenge.id);

      return;
    }

    Navigator.pushNamed(context, Routes.review, arguments: challenge);
  }

  // ============================================================
  // CATEGORY COUNTS
  // ============================================================

  List<MapEntry<String, int>> _categoryCounts(List<Challenge> challenges) {
    final counts = <String, int>{};

    for (final challenge in challenges) {
      final category = challenge.category.trim();

      if (category.isEmpty) {
        continue;
      }

      counts[category] = (counts[category] ?? 0) + 1;
    }

    final entries = counts.entries.toList();

    entries.sort((a, b) => b.value.compareTo(a.value));

    return entries;
  }

  // ============================================================
  // LAST 7 DAYS
  // ============================================================

  _ChartSeries _lastSevenDaySeries(List<Challenge> challenges) {
    final now = DateTime.now();

    final labels = <String>[];

    final values = <int>[];

    for (var i = 6; i >= 0; i--) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i));

      final nextDate = date.add(const Duration(days: 1));

      final count = challenges.where((challenge) {
        return !challenge.createdAt.isBefore(date) &&
            challenge.createdAt.isBefore(nextDate);
      }).length;

      labels.add('${date.day}/${date.month}');

      values.add(count);
    }

    return _ChartSeries(labels: labels, values: values);
  }
}

// ============================================================
// HERO
// ============================================================

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.darkPurpleTextGradient,
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.14),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complaint Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '$total ${total == 1 ? 'complaint' : 'complaints'} matching the current filters',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// METRIC CARD
// ============================================================

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY ROW
// ============================================================

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.name,
    required this.count,
    required this.total,
  });

  final String name;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final value = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(width: 5),

              Text(
                '(${(value * 100).round()}%)',
                style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ),

          const SizedBox(height: 7),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0F2F5),
              color: AppColors.admin,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STATUS SUMMARY
// ============================================================

class _StatusSummaryChip extends StatelessWidget {
  const _StatusSummaryChip({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),

          const SizedBox(width: 6),

          Text(
            '$label  $count',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// COMPLAINT CARD
// ============================================================

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(challenge.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE1E7EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${_shortId(challenge.id)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      challenge.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.title,
                ),
              ),

              const SizedBox(height: 9),

              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 15,
                    color: AppColors.admin,
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      challenge.category,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.muted,
                  ),

                  const SizedBox(width: 4),

                  Flexible(
                    child: Text(
                      challenge.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _MiniInfo(
                    icon: Icons.person_outline,
                    text: challenge.submittedBy.trim().isEmpty
                        ? 'Citizen'
                        : challenge.submittedBy,
                  ),

                  const Spacer(),

                  _MiniInfo(
                    icon: Icons.schedule_outlined,
                    text: _formatDate(challenge.createdAt),
                  ),

                  const SizedBox(width: 7),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.muted),

        const SizedBox(width: 4),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.title,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyComplaints extends StatelessWidget {
  const _EmptyComplaints();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: const Column(
        children: [
          Icon(Icons.filter_alt_off_outlined, size: 40, color: AppColors.muted),

          SizedBox(height: 10),

          Text(
            'No complaints found',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),

          SizedBox(height: 4),

          Text(
            'Try changing or clearing your filters.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 46,
              color: AppColors.muted,
            ),

            const SizedBox(height: 12),

            const Text(
              'Unable to load analytics',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 7),

            Text(message, textAlign: TextAlign.center),

            const SizedBox(height: 16),

            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ANALYTICS STATS
// ============================================================

class _AnalyticsStats {
  const _AnalyticsStats({
    required this.total,
    required this.submitted,
    required this.underReview,
    required this.assigned,
    required this.inProgress,
    required this.deployed,
    required this.resolved,
  });

  final int total;
  final int submitted;
  final int underReview;
  final int assigned;
  final int inProgress;
  final int deployed;
  final int resolved;

  int get active => assigned + inProgress + deployed;

  factory _AnalyticsStats.from(List<Challenge> challenges) {
    int count(bool Function(String status) test) {
      return challenges.where((challenge) {
        return test(challenge.status.trim().toLowerCase());
      }).length;
    }

    return _AnalyticsStats(
      total: challenges.length,

      submitted: count((status) => status == 'submitted'),

      underReview: count((status) => status == 'under review'),

      assigned: count((status) => status.startsWith('assigned')),

      inProgress: count((status) => status == 'in progress'),

      deployed: count(
        (status) => status == 'solution deployed' || status == 'deployed',
      ),

      resolved: count(
        (status) => status == 'resolved' || status == 'completed',
      ),
    );
  }
}

// ============================================================
// CHART
// ============================================================

class _ChartSeries {
  const _ChartSeries({required this.labels, required this.values});

  final List<String> labels;
  final List<int> values;
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE9EDF3)
      ..strokeWidth = 1;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * i / 4;

      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxValue = values.fold<int>(
      1,
      (previous, value) => value > previous ? value : previous,
    );

    final linePaint = Paint()
      ..color = AppColors.admin
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = AppColors.admin.withOpacity(.08)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppColors.admin
      ..style = PaintingStyle.fill;

    final path = Path();

    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);

      final normalized = values[i] / maxValue;

      final y = size.height - (normalized * (size.height * .82)) - 8;

      if (i == 0) {
        path.moveTo(x, y);

        fillPath.moveTo(x, size.height);

        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);

        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }

    fillPath.lineTo(size.width, size.height);

    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

// ============================================================
// HELPERS
// ============================================================

Color _statusColor(String status) {
  final value = status.trim().toLowerCase();

  if (value == 'submitted') {
    return const Color(0xFF667085);
  }

  if (value == 'under review') {
    return Colors.orange;
  }

  if (value.startsWith('assigned')) {
    return AppColors.admin;
  }

  if (value == 'in progress') {
    return Colors.blue;
  }

  if (value == 'solution deployed' || value == 'deployed') {
    return Colors.deepPurple;
  }

  if (value == 'resolved' || value == 'completed') {
    return Colors.green;
  }

  return AppColors.muted;
}

String _shortId(String id) {
  if (id.length <= 8) {
    return id.toUpperCase();
  }

  return id.substring(0, 8).toUpperCase();
}

String _formatDate(DateTime date) {
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

  return '${date.day} '
      '${months[date.month - 1]} '
      '${date.year}';
}

import 'package:flutter/material.dart';

import '../../../apis/admin_api.dart';
import '../../../models/university_model.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';
import '../../auth/controllers/auth_controller.dart';
import 'registration_approvals_view.dart';

class RegistrationDetailsView extends StatefulWidget {
  const RegistrationDetailsView({super.key, required this.user});

  final UserModel user;

  @override
  State<RegistrationDetailsView> createState() =>
      _RegistrationDetailsViewState();
}

class _RegistrationDetailsViewState extends State<RegistrationDetailsView> {
  final AdminApi api = AdminApi();

  late Future<_RegistrationDetailsData> _dataFuture;

  bool busy = false;

  @override
  void initState() {
    super.initState();

    _dataFuture = _loadData();
  }

  @override
  void didUpdateWidget(covariant RegistrationDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.uid != widget.user.uid) {
      _dataFuture = _loadData();
    }
  }

  // ============================================================
  // LOAD REQUEST + CANONICAL UNIVERSITY MATCHES
  // ============================================================

  Future<_RegistrationDetailsData> _loadData() async {
    final request = await api.getRequest(widget.user);

    List<UniversityModel> universityCandidates = const [];

    if (request.user.role == UserRole.university &&
        request.organization != null) {
      universityCandidates = await api.findUniversityCandidates(
        request.organization!,
      );
    }

    return _RegistrationDetailsData(
      request: request,
      universityCandidates: universityCandidates,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !busy,
      child: PageFrame(
        title: 'Registration Details',
        color: AppColors.admin,
        child: FutureBuilder<_RegistrationDetailsData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildError(snapshot.error!);
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data!;

            final request = data.request;

            final user = request.user;

            final org = request.organization;

            final details = <String, String?>{
              'Role': getRoleConfig(user.role).title,

              'Name': request.name,

              if (org != null) ...{
                if (user.role == UserRole.university)
                  'University Type': org.category,

                if (user.role == UserRole.industry)
                  'Industry Sector': org.sector,

                'Website': org.website,

                'Address': org.address,

                'City': org.city,

                'State': org.state,
              },

              'Official Email': user.email,

              'Phone': user.phone,

              'Contact Person': user.fullName,

              'Designation': user.designation,

              'Registration Date': registrationDate(user.createdAt),

              'Status': user.status,

              if (user.organizationId != null)
                'Registration Organization ID': user.organizationId,

              if (user.universityId != null)
                'Canonical University ID': user.universityId,
            };

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                // ==================================================
                // HEADER
                // ==================================================
                _RegistrationHeader(user: user, name: request.name),

                const SizedBox(height: 20),

                // ==================================================
                // REGISTRATION DETAILS
                // ==================================================
                _sectionTitle(
                  'Registration Information',
                  'Details submitted during registration.',
                ),

                const SizedBox(height: 10),

                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final field in details.entries.where(
                        (entry) =>
                            entry.value != null &&
                            entry.value!.trim().isNotEmpty,
                      )) ...[
                        _DetailField(label: field.key, value: field.value!),

                        if (field.key !=
                            details.entries
                                .where(
                                  (entry) =>
                                      entry.value != null &&
                                      entry.value!.trim().isNotEmpty,
                                )
                                .last
                                .key)
                          const Divider(height: 25),
                      ],
                    ],
                  ),
                ),

                // ==================================================
                // UNIVERSITY CANONICAL LINKING
                // ==================================================
                if (user.role == UserRole.university) ...[
                  const SizedBox(height: 28),

                  _sectionTitle(
                    'University Identity',
                    'Link this registration to a canonical university before approval.',
                  ),

                  const SizedBox(height: 10),

                  _buildUniversitySection(data),
                ],

                // ==================================================
                // BUSY
                // ==================================================
                if (busy) ...[
                  const SizedBox(height: 22),

                  const Center(child: CircularProgressIndicator()),
                ],

                const SizedBox(height: 28),

                // ==================================================
                // ACTIONS
                // ==================================================
                if (user.role != UserRole.university)
                  _buildNormalActions(user)
                else
                  _buildUniversityBottomActions(data),
              ],
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // UNIVERSITY SECTION
  // ============================================================

  Widget _buildUniversitySection(_RegistrationDetailsData data) {
    final request = data.request;

    final org = request.organization;

    if (org == null) {
      return _WarningCard(
        icon: Icons.error_outline_rounded,
        title: 'Organization record missing',
        message:
            'This university registration cannot be approved until its organization record is recovered.',
        color: Colors.redAccent,
      );
    }

    final matches = data.universityCandidates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.admin.withOpacity(.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.admin.withOpacity(.12)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.account_tree_outlined, color: AppColors.admin),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'The registration organization and canonical university are separate records. '
                  'Choose an existing university whenever possible to avoid duplicate university identities.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Possible Existing Universities',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.admin.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${matches.length}',
                style: TextStyle(
                  color: AppColors.admin,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        const Text(
          'Matches are based on canonical university information such as name and institution domain.',
          style: TextStyle(color: AppColors.muted, fontSize: 11.5),
        ),

        const SizedBox(height: 12),

        if (matches.isEmpty)
          const _WarningCard(
            icon: Icons.search_off_rounded,
            title: 'No existing match found',
            message:
                'Review the university details carefully before creating a new canonical university.',
            color: Colors.orange,
          )
        else
          for (final university in matches) ...[
            _UniversityMatchCard(
              university: university,
              busy: busy,
              onApprove: () => _linkExistingUniversity(university),
            ),

            const SizedBox(height: 12),
          ],

        const SizedBox(height: 8),

        const Divider(),

        const SizedBox(height: 15),

        const Text(
          'No correct university above?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),

        const SizedBox(height: 5),

        const Text(
          'Create a new canonical university only when this institution genuinely does not already exist.',
          style: TextStyle(color: AppColors.muted, fontSize: 11.5, height: 1.4),
        ),

        const SizedBox(height: 13),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: busy ? null : () => _createNewUniversity(data),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Create New University & Approve'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UNIVERSITY BOTTOM ACTION
  // ============================================================

  Widget _buildUniversityBottomActions(_RegistrationDetailsData data) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : _reject,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject Registration'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NORMAL NON-UNIVERSITY ACTIONS
  // ============================================================

  Widget _buildNormalActions(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: busy ? null : _reject,
            child: const Text('Reject'),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: ElevatedButton(
            onPressed: busy ? null : () => _approveNormal(user),
            child: const Text('Approve'),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LINK EXISTING UNIVERSITY
  // ============================================================

  Future<void> _linkExistingUniversity(UniversityModel university) async {
    if (busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Link and approve?'),
          content: Text(
            'This account will be linked to:\n\n'
            '${university.name}\n'
            '${university.id}\n\n'
            'All challenges assigned to this university ID will become available to this approved university account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Link & Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      () async {
        await api.approveUniversityRegistration(
          uid: widget.user.uid,

          universityId: university.id,

          createNewUniversity: false,
        );
      },
      successMessage:
          'University registration linked to ${university.name} and approved.',
    );
  }

  // ============================================================
  // CREATE NEW CANONICAL UNIVERSITY
  // ============================================================

  Future<void> _createNewUniversity(_RegistrationDetailsData data) async {
    if (busy) return;

    final organization = data.request.organization;

    if (organization == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 34,
          ),
          title: const Text('Create new university?'),
          content: Text(
            'A new canonical university will be created for:\n\n'
            '${organization.name}\n\n'
            'Do this only if the university does not already exist in the canonical university master.\n\n'
            'The new university will NOT automatically become ML-eligible until its ML profile/dataset is configured.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Create & Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(
      () async {
        await api.approveUniversityRegistration(
          uid: widget.user.uid,

          createNewUniversity: true,
        );
      },
      successMessage:
          'New canonical university created and registration approved.',
    );
  }

  // ============================================================
  // APPROVE NON-UNIVERSITY
  // ============================================================

  Future<void> _approveNormal(UserModel user) async {
    if (busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Approve registration?'),
          content: Text(
            'Approve ${user.fullName} as ${getRoleConfig(user.role).title}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _runAction(() async {
      await api.approveRegistration(uid: widget.user.uid);
    }, successMessage: 'Registration approved successfully.');
  }

  // ============================================================
  // REJECT
  // ============================================================

  Future<void> _reject() async {
    if (busy) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectionDialog(),
    );

    if (reason == null || !mounted) {
      return;
    }

    await _runAction(() async {
      await api.rejectRegistration(uid: widget.user.uid, reason: reason);
    }, successMessage: 'Registration rejected successfully.');
  }

  // ============================================================
  // RUN ACTION
  // ============================================================

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (busy) return;

    setState(() {
      busy = true;
    });

    try {
      await action();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(successMessage),
            behavior: SnackBarBehavior.floating,
          ),
        );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(authErrorMessage(error)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 42,
            ),

            const SizedBox(height: 12),

            Text(authErrorMessage(error), textAlign: TextAlign.center),

            const SizedBox(height: 14),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  _dataFuture = _loadData();
                });
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.title,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PAGE DATA
// ============================================================

class _RegistrationDetailsData {
  const _RegistrationDetailsData({
    required this.request,
    required this.universityCandidates,
  });

  final RegistrationRequest request;

  final List<UniversityModel> universityCandidates;
}

// ============================================================
// HEADER
// ============================================================

class _RegistrationHeader extends StatelessWidget {
  const _RegistrationHeader({required this.user, required this.name});

  final UserModel user;
  final String name;

  @override
  Widget build(BuildContext context) {
    final config = getRoleConfig(user.role);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.darkPurpleTextGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: Colors.white),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${config.title} Registration',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          StatusPill(user.status),
        ],
      ),
    );
  }
}

// ============================================================
// DETAIL FIELD
// ============================================================

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 4),

        SelectableText(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.title,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// UNIVERSITY MATCH
// ============================================================

class _UniversityMatchCard extends StatelessWidget {
  const _UniversityMatchCard({
    required this.university,
    required this.busy,
    required this.onApprove,
  });

  final UniversityModel university;
  final bool busy;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE1E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppColors.admin.withOpacity(.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_outlined, color: AppColors.admin),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      university.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 3),

                    SelectableText(
                      university.id,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: university.mlEligible
                      ? Colors.green.withOpacity(.08)
                      : Colors.orange.withOpacity(.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  university.mlEligible ? 'ML Ready' : 'Not ML Ready',
                  style: TextStyle(
                    color: university.mlEligible ? Colors.green : Colors.orange,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          if (university.domain.trim().isNotEmpty)
            _UniversityInfo(
              icon: Icons.language_rounded,
              text: university.domain,
            ),

          if (university.city.trim().isNotEmpty ||
              university.state.trim().isNotEmpty) ...[
            const SizedBox(height: 6),

            _UniversityInfo(
              icon: Icons.location_on_outlined,
              text: [
                university.city,
                university.state,
              ].where((value) => value.trim().isNotEmpty).join(', '),
            ),
          ],

          if (university.type.trim().isNotEmpty) ...[
            const SizedBox(height: 6),

            _UniversityInfo(
              icon: Icons.account_balance_outlined,
              text: university.type,
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: busy ? null : onApprove,
              icon: const Icon(Icons.link_rounded),
              label: const Text('Link & Approve'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.admin),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityInfo extends StatelessWidget {
  const _UniversityInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.muted),

        const SizedBox(width: 6),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// WARNING
// ============================================================

class _WarningCard extends StatelessWidget {
  const _WarningCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11.5,
                    height: 1.4,
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
// REJECTION DIALOG
// ============================================================

class _RejectionDialog extends StatefulWidget {
  const _RejectionDialog();

  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final TextEditingController reason = TextEditingController();

  final GlobalKey<FormState> form = GlobalKey<FormState>();

  @override
  void dispose() {
    reason.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject this registration?'),
      content: Form(
        key: form,
        child: TextFormField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Reason for rejection'),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'A rejection reason is required.';
            }

            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: () {
            if (!form.currentState!.validate()) {
              return;
            }

            Navigator.pop(context, reason.text.trim());
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

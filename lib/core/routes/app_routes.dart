import 'package:flutter/material.dart';

import '../../features/admin/views/admin_views.dart' show AdminDashboard;
import '../../features/admin/views/analytics_view.dart';
import '../../features/admin/views/challange_review.dart';
import '../../features/admin/views/project_monitoring.dart';
import '../../features/admin/views/registration_approvals_view.dart';
import '../../features/admin/views/registration_details_view.dart';

import '../../features/auth/views/otp_view.dart';
import '../../features/auth/views/registration_screen.dart';
import '../../features/auth/views/role_selection_screen.dart';
import '../../features/auth/views/session_gate.dart';
import '../../features/auth/views/welcome_view.dart';

import '../../features/citizen/views/citizen_dashboard.dart'
    show CitizenDashboard;
import '../../features/citizen/views/submit_challange_view.dart';
import '../../features/citizen/views/submit_success_screen.dart';
import '../../features/citizen/views/trach_challange_view.dart';

import '../../features/university/views/university_views.dart'
    show UniversityDashboard;
import '../../features/university/views/create_project_view.dart';
import '../../features/university/views/project_workspace.dart';
import '../../features/university/views/university_challange_details_view.dart';

import '../../features/industry/views/industry_views.dart';

import '../../models/challenge_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';

class Routes {
  static const welcome = '/';
  static const roleSelection = '/roles';
  static const login = '/login';
  static const otp = '/otp';
  static const registration = '/register';
  static const pending = '/account-status';

  // ============================================================
  // ADMIN
  // ============================================================

  static const approvals = '/admin/approvals';
  static const registrationDetails = '/admin/registration';
  static const admin = '/admin';
  static const review = '/admin/review';
  static const analytics = '/admin/analytics';
  static const monitoring = '/admin/projects';

  // ============================================================
  // CITIZEN
  // ============================================================

  static const citizen = '/citizen';
  static const submit = '/submit';
  static const details = '/details';
  static const success = '/success';
  static const track = '/track';

  // ============================================================
  // UNIVERSITY
  // ============================================================

  static const university = '/university';
  static const challengeDetail = '/university/challenge';
  static const createProject = '/university/create';
  static const workspace = '/university/workspace';

  // ============================================================
  // INDUSTRY
  // ============================================================

  static const industry = '/industry';
  static const projectDetail = '/industry/project';
  static const interest = '/industry/interest';
  static const collaborations = '/industry/collaborations';
  static const chat = '/industry/chat';
}

class AppRoutes {
  static Route<dynamic> generate(RouteSettings settings) {
    final arguments = settings.arguments;

    Widget page;

    switch (settings.name) {
      // ========================================================
      // AUTH
      // ========================================================

      case Routes.welcome:
        page = const SessionGate(restore: true, child: WelcomeView());
        break;

      case Routes.login:
      case Routes.roleSelection:
        page = const RoleSelectionScreen();
        break;

      case Routes.registration:
        page = arguments is UserRole
            ? RegistrationScreen(role: arguments)
            : const RoleSelectionScreen();
        break;

      case Routes.pending:
        page = const SessionGate(statusPage: true, child: SizedBox.shrink());
        break;

      case Routes.otp:
        page = const OtpView();
        break;

      // ========================================================
      // CITIZEN
      // ========================================================

      case Routes.citizen:
        page = const CitizenDashboard();
        break;

      case Routes.submit:
        page = const SubmitChallengeView();
        break;

      case Routes.success:
        if (arguments is! Challenge) {
          page = const _InvalidRouteArguments(
            message: 'SubmissionSuccess requires a Challenge.',
          );
          break;
        }

        page = SubmissionSuccess(challenge: arguments);
        break;

      case Routes.track:
        if (arguments is! String) {
          page = const _InvalidRouteArguments(
            message: 'Track Challenge requires a challenge ID.',
          );
          break;
        }

        page = TrackChallengeView(challengeId: arguments);
        break;

      // ========================================================
      // UNIVERSITY
      // ========================================================

      case Routes.university:
        page = const UniversityDashboard();
        break;

      case Routes.challengeDetail:
        if (arguments is! String) {
          page = const _InvalidRouteArguments(
            message: 'University Challenge Details requires a challenge ID.',
          );
          break;
        }

        page = UniversityChallengeDetails(challengeId: arguments);
        break;

      case Routes.createProject:
        if (arguments is! String) {
          page = const _InvalidRouteArguments(
            message: 'Create Project requires a challenge ID.',
          );
          break;
        }

        page = CreateProjectView(challengeId: arguments);
        break;

      case Routes.workspace:
        if (arguments is! String) {
          page = const _InvalidRouteArguments(
            message: 'Project Workspace requires a challenge ID.',
          );
          break;
        }

        page = ProjectWorkspace(challengeId: arguments);
        break;

      // ========================================================
      // INDUSTRY
      // ========================================================

      case Routes.industry:
        page = const IndustryDashboard();
        break;

      case Routes.projectDetail:
        if (arguments is! Project) {
          page = const _InvalidRouteArguments(
            message: 'Project Details requires a Project.',
          );
          break;
        }

        page = ProjectDetails(p: arguments);
        break;

      case Routes.interest:
        if (arguments is! Project) {
          page = const _InvalidRouteArguments(
            message: 'Express Interest requires a Project.',
          );
          break;
        }

        page = ExpressInterest(p: arguments);
        break;

      case Routes.collaborations:
        page = const Collaborations();
        break;

      case Routes.chat:
        page = const CollaborationChat();
        break;

      // ========================================================
      // ADMIN
      // ========================================================

      case Routes.admin:
        page = const AdminDashboard();
        break;

      case Routes.approvals:
        page = const RegistrationApprovalsView();
        break;

      case Routes.registrationDetails:
        if (arguments is! UserModel) {
          page = const _InvalidRouteArguments(
            message: 'Registration Details requires a UserModel.',
          );
          break;
        }

        page = RegistrationDetailsView(user: arguments);
        break;

      case Routes.review:
        if (arguments is! Challenge) {
          page = const _InvalidRouteArguments(
            message: 'Challenge Review requires a Challenge.',
          );
          break;
        }

        page = ChallengeReview(x: arguments);
        break;

      case Routes.analytics:
        page = const AnalyticsView();
        break;

      case Routes.monitoring:
        if (arguments is! String) {
          page = const _InvalidRouteArguments(
            message: 'Project Monitoring requires a challenge ID.',
          );
          break;
        }

        page = ProjectMonitoring(challengeId: arguments);
        break;

      // ========================================================
      // UNKNOWN
      // ========================================================

      default:
        page = const SessionGate(restore: true, child: WelcomeView());
    }

    // ==========================================================
    // ROLE GUARD
    // ==========================================================

    final requiredRole = switch (settings.name) {
      Routes.citizen ||
      Routes.submit ||
      Routes.details ||
      Routes.success ||
      Routes.track => UserRole.citizen,

      Routes.university ||
      Routes.challengeDetail ||
      Routes.createProject ||
      Routes.workspace => UserRole.university,

      Routes.industry ||
      Routes.projectDetail ||
      Routes.interest ||
      Routes.collaborations ||
      Routes.chat => UserRole.industry,

      Routes.admin ||
      Routes.review ||
      Routes.analytics ||
      Routes.monitoring ||
      Routes.approvals ||
      Routes.registrationDetails => UserRole.admin,

      _ => null,
    };

    final guardedPage = requiredRole == null
        ? page
        : SessionGate(requiredRole: requiredRole, child: page);

    return MaterialPageRoute(settings: settings, builder: (_) => guardedPage);
  }
}

// ============================================================
// INVALID ROUTE ARGUMENT
// Prevents ugly "String is not subtype of Challenge" crashes.
// ============================================================

class _InvalidRouteArguments extends StatelessWidget {
  const _InvalidRouteArguments({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unable to Open Page')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.redAccent,
              ),

              const SizedBox(height: 14),

              Text(message, textAlign: TextAlign.center),

              const SizedBox(height: 18),

              FilledButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

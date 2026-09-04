import 'package:flutter/material.dart';
import '../../features/auth/views/auth_views.dart';
import '../../features/citizen/views/citizen_views.dart';
import '../../features/university/views/university_views.dart';
import '../../features/industry/views/industry_views.dart';
import '../../features/admin/views/admin_views.dart';
import '../../models/challenge_model.dart';
import '../../models/project_model.dart';

class Routes {
  static const welcome = '/',
      login = '/login',
      otp = '/otp',
      citizen = '/citizen',
      submit = '/submit',
      details = '/details',
      success = '/success',
      track = '/track',
      university = '/university',
      challengeDetail = '/university/challenge',
      createProject = '/university/create',
      workspace = '/university/workspace',
      industry = '/industry',
      projectDetail = '/industry/project',
      interest = '/industry/interest',
      collaborations = '/industry/collaborations',
      chat = '/industry/chat',
      admin = '/admin',
      review = '/admin/review',
      analytics = '/admin/analytics',
      monitoring = '/admin/projects';
}

class AppRoutes {
  static Route<dynamic> generate(RouteSettings x) {
    final a = x.arguments;
    Widget page;
    switch (x.name) {
      case Routes.welcome:
        page = const WelcomeView();
        break;
      case Routes.login:
        page = const LoginView();
        break;
      case Routes.otp:
        page = const OtpView();
        break;
      case Routes.citizen:
        page = const CitizenDashboard();
        break;
      case Routes.submit:
        page = const SubmitChallengeView();
        break;
      case Routes.details:
        page = AddDetailsView(draft: a as List<String>);
        break;
      case Routes.success:
        page = SubmissionSuccess(challenge: a as Challenge);
        break;
      case Routes.track:
        page = TrackChallengeView(x: a as Challenge);
        break;
      case Routes.university:
        page = const UniversityDashboard();
        break;
      case Routes.challengeDetail:
        page = UniversityChallengeDetails(x: a as Challenge);
        break;
      case Routes.createProject:
        page = CreateProjectView(challenge: a as Challenge);
        break;
      case Routes.workspace:
        page = ProjectWorkspace(p: a as Project);
        break;
      case Routes.industry:
        page = const IndustryDashboard();
        break;
      case Routes.projectDetail:
        page = ProjectDetails(p: a as Project);
        break;
      case Routes.interest:
        page = ExpressInterest(p: a as Project);
        break;
      case Routes.collaborations:
        page = const Collaborations();
        break;
      case Routes.chat:
        page = const CollaborationChat();
        break;
      case Routes.admin:
        page = const AdminDashboard();
        break;
      case Routes.review:
        page = ChallengeReview(x: a as Challenge);
        break;
      case Routes.analytics:
        page = const AnalyticsView();
        break;
      case Routes.monitoring:
        page = const ProjectMonitoring();
        break;
      default:
        page = const WelcomeView();
    }
    return MaterialPageRoute(settings: x, builder: (_) => page);
  }
}

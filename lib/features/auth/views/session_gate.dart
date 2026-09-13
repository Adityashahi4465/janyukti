import 'package:flutter/material.dart';
import '../../../apis/auth_api.dart';
import '../../../models/user_model.dart';
import '../../../models/user_role.dart';
import '../controllers/auth_controller.dart';
import '../services/auth_session.dart';
import 'pending_approval_screen.dart';
import 'welcome_view.dart';

/// Rechecks the server profile on protected routes and reacts to revocation.
class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.child,
    this.requiredRole,
    this.restore = false,
    this.statusPage = false,
    this.api,
  });
  final AuthApi? api;
  final Widget child;
  final UserRole? requiredRole;
  final bool restore, statusPage;
  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final api = widget.api ?? AuthApi();
  late final bool restoreSession = widget.restore && api.currentUser != null;
  late final authStream = api.authChanges();
  Stream<UserModel?>? profileStream;
  String? profileUid, scheduledRoute;
  void redirect(UserRole role) {
    final route = AuthController.dashboardRoute(role);
    if (scheduledRoute == route) return;
    scheduledRoute = route;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.restore && !restoreSession) return widget.child;
    return StreamBuilder(
      stream: authStream,
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) return loading;
        if (auth.hasError) {
          return error('Unable to restore your session. Please sign in again.');
        }
        final user = auth.data;
        if (user == null) return const WelcomeView();
        if (profileUid != user.uid) {
          profileUid = user.uid;
          profileStream = api.watchUserProfile(user.uid);
        }
        return StreamBuilder<UserModel?>(
          stream: profileStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return loading;
            }
            if (snapshot.hasError) {
              return error(authErrorMessage(snapshot.error!));
            }
            final profile = snapshot.data;
            if (profile == null) {
              return error(
                'Unable to verify your account profile. Check your connection or contact the janYukti administrator.',
              );
            }
            if (widget.requiredRole != null &&
                profile.role != widget.requiredRole) {
              return error(
                'This account does not belong to the selected portal.',
              );
            }
            if (!profile.isActive) {
              return PendingApprovalScreen(profile: profile);
            }
            if (widget.restore || widget.statusPage) {
              redirect(profile.role);
              return loading;
            }
            return widget.child;
          },
        );
      },
    );
  }

  Widget get loading =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
  Widget error(String message) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              TextButton(
                onPressed: () => setState(() {
                  profileUid = null;
                }),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => AuthSession.signOut(context),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

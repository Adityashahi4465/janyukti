import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/user_role.dart';

class AuthController extends ChangeNotifier {
  bool isLoading = false;
  Future<void> login(BuildContext context, UserRole role) async {
    isLoading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!context.mounted) return;
    isLoading = false;
    notifyListeners();
    final route = switch (role) {
      UserRole.citizen => Routes.citizen,
      UserRole.university => Routes.university,
      UserRole.industry => Routes.industry,
      UserRole.admin => Routes.admin,
    };
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }
}

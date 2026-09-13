import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class AuthSession {
  const AuthSession._();
  static Future<void> signOut(BuildContext context) async {
    final controller = AuthController();
    await controller.logout(context);
    if (context.mounted && controller.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.errorMessage!)));
    }
    controller.dispose();
  }
}

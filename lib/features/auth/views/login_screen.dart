import 'package:flutter/material.dart';
import '../../../models/user_role.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import 'role_selection_screen.dart';
import '../../../core/localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role});
  final UserRole role;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(),
      password = TextEditingController(),
      controller = AuthController();
  bool obscure = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = getRoleConfig(widget.role);
    final subtitle = switch (widget.role) {
      UserRole.citizen => 'Welcome back! Continue making a difference.',
      UserRole.university => 'Collaborate on real-world challenges.',
      UserRole.industry => 'Partner with innovation and impact.',
      UserRole.admin => 'Secure access to the JanYukti platform.',
    };
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: controller.isLoading
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                    const SizedBox(height: 18),
                    AuthHeader(
                      icon: config.icon,
                      title: tr(context, '${config.title} Portal'),
                      subtitle: subtitle,
                      color: config.primaryColor,
                    ),
                    const SizedBox(height: 38),
                    AuthTextField(
                      label: tr(context, config.emailLabel),
                      hintText: 'Enter your ${config.emailLabel.toLowerCase()}',
                      controller: email,
                      prefixIcon: Icons.mail_outline,
                      enabled: !controller.isLoading,
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      label: tr(context, 'Password'),
                      hintText: 'Enter your password',
                      controller: password,
                      prefixIcon: Icons.lock_outline,
                      obscureText: obscure,
                      suffixIcon: obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      onSuffixTap: () => setState(() => obscure = !obscure),
                      enabled: !controller.isLoading,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: controller.isLoading ? null : () {},
                        child: Text(
                          tr(context, 'Forgot Password?'),
                          style: TextStyle(
                            color: config.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: controller.isLoading
                            ? null
                            : () => controller.login(context, widget.role),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: controller.isLoading
                            ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                tr(context, config.loginLabel),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: Color(0xFF6D7890),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Not a ${config.title}? ',
                            style: const TextStyle(color: Color(0xFF6D7890)),
                          ),
                          TextButton(
                            onPressed: controller.isLoading
                                ? null
                                : () => Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const RoleSelectionScreen(),
                                    ),
                                    (_) => false,
                                  ),
                            child: Text(
                              tr(context, 'Choose another role'),
                              style: TextStyle(
                                color: config.primaryColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

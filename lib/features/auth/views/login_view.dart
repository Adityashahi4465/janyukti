import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/ui.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  String role = 'Citizen';
  bool signup = false;
  final input = TextEditingController(text: '+91 9876543210');
  final pass = TextEditingController();
  String get route => {
    'Citizen': Routes.otp,
    'University': Routes.university,
    'Industry': Routes.industry,
    'Admin': Routes.admin,
  }[role]!;
  @override
  Widget build(BuildContext c) {
    final color = {
      'Citizen': AppColors.citizen,
      'University': AppColors.university,
      'Industry': AppColors.industry,
      'Admin': AppColors.admin,
    }[role]!;
    return PageFrame(
      title: 'Login / Sign Up',
      color: color,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              for (final x in ['Login', 'Sign Up'])
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => signup = x == 'Sign Up'),
                    child: Text(
                      x,
                      style: TextStyle(
                        color: signup == (x == 'Sign Up')
                            ? color
                            : AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Demo Login As',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          Wrap(
            spacing: 7,
            children: [
              for (final r in ['Citizen', 'University', 'Industry', 'Admin'])
                ChoiceChip(
                  label: Text(r),
                  selected: role == r,
                  onSelected: (_) => setState(() => role = r),
                  selectedColor: color.withOpacity(.18),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: input,
            decoration: InputDecoration(
              labelText: role == 'Citizen' ? 'Mobile number' : 'Email address',
            ),
          ),
          if (role != 'Citizen') ...[
            const SizedBox(height: 14),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
          const SizedBox(height: 22),
          RoleButton(
            label: role == 'Citizen' ? 'Send OTP' : 'Continue as $role',
            color: color,
            onTap: () => Navigator.pushNamed(c, route),
            icon: Icons.arrow_forward,
          ),
        ],
      ),
    );
  }
}

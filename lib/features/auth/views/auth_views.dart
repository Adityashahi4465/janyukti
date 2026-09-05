import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/ui.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});
  @override
  Widget build(BuildContext c) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Icon(Icons.hub_rounded, size: 76, color: AppColors.citizen),
            const SizedBox(height: 16),
            const Text(
              'JanYukti',
              style: TextStyle(
                fontSize: 31,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Together, we solve tomorrow’s challenges today.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.muted),
            ),
            const SizedBox(height: 45),
            Container(
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Icon(
                  Icons.diversity_3,
                  size: 105,
                  color: AppColors.citizen,
                ),
              ),
            ),
            const Spacer(),
            RoleButton(
              label: 'Login / Sign Up',
              color: AppColors.citizen,
              onTap: () => Navigator.pushNamed(c, Routes.login),
              icon: Icons.login,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(c, Routes.citizen),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    ),
  );
}

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

class OtpView extends StatelessWidget {
  const OtpView({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Verify OTP',
      color: AppColors.citizen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(
              Icons.verified_user_outlined,
              size: 72,
              color: AppColors.citizen,
            ),
            const SizedBox(height: 18),
            const Text(
              'Verify your number',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the OTP sent to +91 9876543210',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (_) => const SizedBox(
                  width: 42,
                  child: TextField(
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(counterText: ''),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Resend OTP in 00:25',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            RoleButton(
              label: 'Verify & Continue',
              color: AppColors.citizen,
              icon: Icons.check,
              onTap: () =>
                  Navigator.pushReplacementNamed(context, Routes.citizen),
            ),
          ],
        ),
      ),
    );
  }
}

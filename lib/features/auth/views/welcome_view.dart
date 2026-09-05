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
            Image.asset('assets/janyukti.png'),

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

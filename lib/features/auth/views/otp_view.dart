import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/widgets/ui.dart';

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

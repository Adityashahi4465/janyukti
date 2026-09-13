import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/ui.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});
  @override
  Widget build(BuildContext c) => PageFrame(
    title: 'Analytics Dashboard',
    color: AppColors.admin,
    child: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        section('Challenges over time'),
        AppCard(
          child: SizedBox(
            height: 170,
            child: CustomPaint(painter: _LinePainter()),
          ),
        ),
        section('Top categories'),
        AppCard(
          child: Column(
            children: [
              _row('Water Management', .62, AppColors.admin),
              _row('Agriculture', .42, AppColors.citizen),
              _row('Healthcare', .28, AppColors.industry),
            ],
          ),
        ),
        section('Status summary'),
        AppCard(
          child: const Wrap(
            spacing: 12,
            children: [
              StatusPill('In Progress'),
              StatusPill('Under Review'),
              StatusPill('Assigned'),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _row(String x, double v, Color c) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(width: 130, child: Text(x)),
        Expanded(
          child: LinearProgressIndicator(value: v, color: c),
        ),
        const SizedBox(width: 8),
        Text('${(v * 100).round()}%'),
      ],
    ),
  );
}

class _LinePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.admin
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(4, s.height * .75)
      ..lineTo(s.width * .18, s.height * .55)
      ..lineTo(s.width * .35, s.height * .68)
      ..lineTo(s.width * .52, s.height * .35)
      ..lineTo(s.width * .7, s.height * .48)
      ..lineTo(s.width - 4, s.height * .16);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

import 'package:flutter/material.dart';
import 'package:salat_pro/utils/moon_utils.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:hijri/hijri_calendar.dart';
import 'dart:math' as math;

class MoonPhaseScreen extends StatelessWidget {
  const MoonPhaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final moonData = MoonUtils.getMoonPhase(DateTime.now(), s.isArabic);
    final hijriDate = HijriCalendar.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.moonPhaseTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.05),
                ),
                child: CustomPaint(
                  painter: MoonPainter(moonData.phasePercent),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              moonData.phaseName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildMoonInfoRow(
                      context,
                      s.illumination,
                      "${moonData.illumination.toStringAsFixed(1)}%",
                    ),
                    const Divider(height: 32),
                    _buildMoonInfoRow(
                      context,
                      s.moonAgeLabel,
                      "${moonData.ageInDays.toStringAsFixed(1)} ${s.days}",
                    ),
                    const Divider(height: 32),
                    _buildMoonInfoRow(
                      context,
                      s.hijriMonthLabel,
                      s.hijriMonthName(hijriDate.hMonth),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.moonPhaseFootnote,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoonInfoRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class MoonPainter extends CustomPainter {
  final double phase; // 0.0 to 1.0

  MoonPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final bgPaint = Paint()..color = Colors.black87;
    final moonPaint = Paint()..color = Colors.amber.shade100;

    // Draw the background (dark part of the moon)
    canvas.drawCircle(center, radius, bgPaint);

    // Drawing moon phase using clipPath or bezier curves
    // For simplicity, we can use a simpler approach of overlapping ellipses or a math representation
    final path = Path();
    
    // We treat moon phase as a combination of two semicircles and changing the curve
    if (phase <= 0.5) {
      // Waxing phases
      double x = math.cos(2 * math.pi * phase);
      // Rect for half moon
      path.addArc(Rect.fromCircle(center: center, radius: radius), math.pi / 2, math.pi);
      // The inner curve - we use an ellipse that changes width
      path.addArc(Rect.fromCenter(center: center, width: radius * 2 * x, height: radius * 2), -math.pi / 2, math.pi);
    } else {
      // Waning phases
      double x = math.cos(2 * math.pi * phase);
      path.addArc(Rect.fromCircle(center: center, radius: radius), -math.pi / 2, math.pi);
      path.addArc(Rect.fromCenter(center: center, width: radius * 2 * x, height: radius * 2), math.pi / 2, math.pi);
    }
    
    canvas.drawPath(path, moonPaint);
    
    // Add glow
    final glowPaint = Paint()
      ..color = Colors.amber.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant MoonPainter oldDelegate) => oldDelegate.phase != phase;
}

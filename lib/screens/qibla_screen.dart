import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'dart:math' as math;
import 'dart:ui' show FontFeature, ImageFilter;
import 'package:salat_pro/core/app_colors.dart';
import 'package:salat_pro/utils/location_utils.dart';
import 'package:salat_pro/l10n/app_strings.dart';
import 'package:salat_pro/l10n/l10n.dart';
import 'package:salat_pro/utils/platform_support.dart';
import 'package:geolocator/geolocator.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Future<double?>? _distanceKmFuture;

  @override
  void initState() {
    super.initState();
    _distanceKmFuture = _loadDistanceToKaabaKm();
  }

  Future<double?> _loadDistanceToKaabaKm() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationUtils.distanceToKaabaKm(last.latitude, last.longitude);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return LocationUtils.distanceToKaabaKm(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final s = context.strings;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.background, palette.surface],
          ),
        ),
        child: SafeArea(
          child: supportsQiblahCompass ? _buildMobileQibla(context, s) : _buildStaticQibla(context, s),
        ),
      ),
    );
  }

  /// Web, Windows, Linux, etc.: bearing from GPS only (no device compass stream).
  Widget _buildStaticQibla(BuildContext context, AppStrings s) {
    return FutureBuilder<Position>(
      future: Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final palette = context.palette;
          return Center(
            child: CircularProgressIndicator(color: palette.primary.withValues(alpha: 0.95)),
          );
        }

        if (snapshot.hasError) {
          final palette = context.palette;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  "${s.locationAccessRequired}\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary.withValues(alpha: 0.95)),
                ),
              ],
            ),
          );
        }

        final pos = snapshot.data!;
        final qiblaDegree = LocationUtils.calculateQibla(pos.latitude, pos.longitude);
        final distanceKm = LocationUtils.distanceToKaabaKm(pos.latitude, pos.longitude);

        return _buildQiblaUI(
          context,
          qiblaDegree,
          0,
          isWeb: true,
          fixedDistanceKm: distanceKm,
          strings: s,
        );
      },
    );
  }

  Widget _buildMobileQibla(BuildContext context, AppStrings s) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final palette = context.palette;
          return Center(
            child: CircularProgressIndicator(color: palette.primary.withValues(alpha: 0.95)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(s.errorLine(snapshot.error!), style: const TextStyle(color: Colors.red)),
          );
        }

        final qiblahDirection = snapshot.data!;
        return _buildQiblaUI(
          context,
          qiblahDirection.qiblah,
          qiblahDirection.direction,
          isWeb: false,
          fixedDistanceKm: null,
          strings: s,
        );
      },
    );
  }

  double _alignmentDeltaDegrees(double qibla, double direction) {
    final d = (direction - qibla + 360) % 360;
    return d > 180 ? 360 - d : d;
  }

  /// Shortest rotation from current heading to qibla (clockwise degrees on the horizon).
  String _turnHintLabel(BuildContext context, double qibla, double direction) {
    final strings = context.strings;
    final cw = (qibla - direction + 360) % 360;
    if (cw <= 180) {
      return strings.turnRight(cw);
    }
    return strings.turnLeft(360 - cw);
  }

  Widget _buildQiblaUI(
    BuildContext context,
    double qibla,
    double direction, {
    required bool isWeb,
    double? fixedDistanceKm,
    required AppStrings strings,
  }) {
    final delta = _alignmentDeltaDegrees(qibla, direction);
    final aligned = !isWeb && delta < 4.5;
    final dialSize = math.min(340.0, MediaQuery.sizeOf(context).shortestSide * 0.82);

    return LayoutBuilder(
      builder: (context, constraints) {
        final palette = context.palette;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(
                    palette,
                    strings,
                    qibla,
                    aligned,
                    isWeb,
                    alignmentDelta: delta,
                    turnHint: _turnHintLabel(context, qibla, direction),
                  ),
                  const SizedBox(height: 20),
                  _buildCompassStack(context, palette, dialSize, qibla, direction),
                  const SizedBox(height: 28),
                  _buildDistanceCard(palette, strings, fixedDistanceKm: fixedDistanceKm),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    AppPalette palette,
    AppStrings strings,
    double qibla,
    bool aligned,
    bool isWeb, {
    required double alignmentDelta,
    required String turnHint,
  }) {
    return Column(
      children: [
        Text(
          strings.qiblaHeading,
          style: TextStyle(
            color: palette.textSecondary.withValues(alpha: 0.9),
            letterSpacing: 6,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.qiblaArabicCaption,
          style: TextStyle(
            color: palette.secondary.withValues(alpha: 0.85),
            fontSize: 13,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                palette.surfaceHigh.withValues(alpha: 0.9),
                palette.surfaceMedium.withValues(alpha: 0.85),
              ],
            ),
            border: Border.all(color: palette.primary.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.explore_rounded,
                color: palette.primary.withValues(alpha: 0.9),
                size: 28,
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${qibla.toStringAsFixed(1)}°',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary.withValues(alpha: 0.98),
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.azimuthFromNorth,
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.textSecondary.withValues(alpha: 0.95),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isWeb)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              strings.compassUnavailableWeb,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.textSecondary.withValues(alpha: 0.85),
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ),
        if (!isWeb) ...[
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: aligned
                ? _AlignedChip(key: const ValueKey('on'), label: strings.facingQibla(alignmentDelta))
                : _AlignHintChip(key: const ValueKey('off'), turnHint: turnHint),
          ),
        ],
      ],
    );
  }

  Widget _buildCompassStack(
    BuildContext context,
    AppPalette palette,
    double dialSize,
    double qibla,
    double direction,
  ) {
    return SizedBox(
      height: dialSize + 16,
      width: dialSize + 16,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Soft outer glow
          Container(
            width: dialSize + 24,
            height: dialSize + 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: palette.primary.withValues(alpha: 0.12),
                  blurRadius: 48,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: palette.secondary.withValues(alpha: 0.06),
                  blurRadius: 64,
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: (direction * (math.pi / 180) * -1),
            child: _CompassDial(size: dialSize, palette: palette),
          ),
          Transform.rotate(
            angle: (qibla * (math.pi / 180) * -1),
            child: _QiblaNeedleOverlay(size: dialSize, palette: palette),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCard(AppPalette palette, AppStrings strings, {double? fixedDistanceKm}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: BoxDecoration(
            color: palette.glassBase.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.glassStroke),
          ),
          child: fixedDistanceKm != null
              ? _distanceRow(palette, strings, fixedDistanceKm)
              : FutureBuilder<double?>(
                  future: _distanceKmFuture,
                  builder: (context, snapshot) {
                    final p = palette;
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: p.primary.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            strings.measuringDistance,
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textSecondary.withValues(alpha: 0.95),
                            ),
                          ),
                        ],
                      );
                    }
                    final km = snapshot.data;
                    if (km == null) {
                      return Text(
                        strings.distanceUnavailable,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.textSecondary.withValues(alpha: 0.95),
                        ),
                      );
                    }
                    return _distanceRow(p, strings, km);
                  },
                ),
        ),
      ),
    );
  }

  Widget _distanceRow(AppPalette palette, AppStrings strings, double km) {
    final formatted = km >= 100 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: palette.goldGradient,
            boxShadow: [
              BoxShadow(
                color: palette.secondary.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(Icons.place_rounded, color: palette.onPrimary.withValues(alpha: 0.95), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.distanceToKaaba,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$formatted km',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary.withValues(alpha: 0.98),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                strings.greatCircleHint,
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AlignedChip extends StatelessWidget {
  const _AlignedChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            palette.primary.withValues(alpha: 0.28),
            palette.primary.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: palette.primary.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, color: palette.primary.withValues(alpha: 0.95), size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlignHintChip extends StatelessWidget {
  const _AlignHintChip({super.key, required this.turnHint});

  final String turnHint;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: palette.surfaceHigh.withValues(alpha: 0.65),
        border: Border.all(color: palette.strokeVerySubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.navigation_rounded, color: palette.textSecondary.withValues(alpha: 0.85), size: 20),
          const SizedBox(width: 8),
          Text(
            turnHint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: palette.textSecondary.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({required this.size, required this.palette});

  final double size;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CompassFacePainter(palette: palette),
        size: Size(size, size),
      ),
    );
  }
}

class _QiblaNeedleOverlay extends StatelessWidget {
  const _QiblaNeedleOverlay({required this.size, required this.palette});

  final double size;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: QiblaNeedlePainter(palette: palette, needleExtent: size * 0.4),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, -0.86),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: palette.goldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: palette.secondary.withValues(alpha: 0.45),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.mosque_rounded, color: palette.onPrimary.withValues(alpha: 0.95), size: 24),
              ),
            ),
          ),
          // Center pivot
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: palette.surfaceHighest,
              border: Border.all(color: palette.secondary.withValues(alpha: 0.85), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.secondary.withValues(alpha: 0.98),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Angle in radians for a compass degree mark (0° = north, clockwise).
double _radFromNorth(int degrees) {
  return -math.pi / 2 + degrees * (math.pi / 180);
}

class CompassFacePainter extends CustomPainter {
  CompassFacePainter({required this.palette});

  final AppPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width / 2;
    final c = Offset(cx, cy);

    final bg = Paint()
      ..shader = RadialGradient(
        colors: [
          palette.surfaceHigh.withValues(alpha: 0.95),
          palette.surface.withValues(alpha: 0.98),
          palette.background.withValues(alpha: 0.92),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: c, radius: radius));

    canvas.drawCircle(c, radius, bg);

    final rimInner = Paint()
      ..shader = SweepGradient(
        colors: [
          palette.secondary.withValues(alpha: 0.35),
          palette.primary.withValues(alpha: 0.2),
          palette.secondary.withValues(alpha: 0.3),
          palette.primary.withValues(alpha: 0.18),
          palette.secondary.withValues(alpha: 0.35),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(c, radius - 2, rimInner);

    final innerRing = Paint()
      ..color = palette.primary.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, radius * 0.72, innerRing);

    // Decorative rays (subtle)
    final rayPaint = Paint()
      ..color = palette.secondary.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 8; i++) {
      final a = _radFromNorth(i * 45);
      canvas.drawLine(
        Offset(cx + math.cos(a) * (radius * 0.35), cy + math.sin(a) * (radius * 0.35)),
        Offset(cx + math.cos(a) * (radius * 0.68), cy + math.sin(a) * (radius * 0.68)),
        rayPaint,
      );
    }

    final minorTick = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final majorTick = Paint()
      ..color = palette.textSecondary.withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var deg = 0; deg < 360; deg += 5) {
      final isMajor = deg % 30 == 0;
      if (!isMajor && deg % 15 != 0) continue;
      final a = _radFromNorth(deg);
      final len = isMajor ? 16.0 : 9.0;
      final w = isMajor ? majorTick : minorTick;
      final innerR = radius - 4 - len;
      final outerR = radius - 4;
      canvas.drawLine(
        Offset(cx + math.cos(a) * innerR, cy + math.sin(a) * innerR),
        Offset(cx + math.cos(a) * outerR, cy + math.sin(a) * outerR),
        w,
      );
    }

    _labelCardinal(canvas, c, radius - 26, 'N', _radFromNorth(0), palette.secondary);
    _labelCardinal(canvas, c, radius - 26, 'E', _radFromNorth(90), palette.textSecondary);
    _labelCardinal(canvas, c, radius - 26, 'S', _radFromNorth(180), palette.textSecondary);
    _labelCardinal(canvas, c, radius - 26, 'W', _radFromNorth(270), palette.textSecondary);

    final degreeStyle = TextStyle(
      color: palette.textSecondary.withValues(alpha: 0.4),
      fontSize: 9,
      fontWeight: FontWeight.w500,
    );
    for (final deg in [30, 60, 120, 150, 210, 240, 300, 330]) {
      _labelAt(canvas, '$deg°', c, radius - 52, _radFromNorth(deg), degreeStyle);
    }
  }

  void _labelCardinal(
    Canvas canvas,
    Offset center,
    double labelRadius,
    String text,
    double angleRad,
    Color color,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = center.dx + labelRadius * math.cos(angleRad) - tp.width / 2;
    final y = center.dy + labelRadius * math.sin(angleRad) - tp.height / 2;
    tp.paint(canvas, Offset(x, y));
  }

  void _labelAt(
    Canvas canvas,
    String text,
    Offset center,
    double labelRadius,
    double angleRad,
    TextStyle style,
  ) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final x = center.dx + labelRadius * math.cos(angleRad) - tp.width / 2;
    final y = center.dy + labelRadius * math.sin(angleRad) - tp.height / 2;
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CompassFacePainter oldDelegate) =>
      oldDelegate.palette != palette;
}

class QiblaNeedlePainter extends CustomPainter {
  QiblaNeedlePainter({required this.palette, required this.needleExtent});

  final AppPalette palette;
  final double needleExtent;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final topY = cy - needleExtent;
    final bottomY = cy + needleExtent * 0.22;

    final shaft = Path()
      ..moveTo(cx, topY + 28)
      ..lineTo(cx - 5, cy - 6)
      ..lineTo(cx - 2, bottomY)
      ..lineTo(cx + 2, bottomY)
      ..lineTo(cx + 5, cy - 6)
      ..close();

    final shaftPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.primary.withValues(alpha: 0.95),
          palette.primary.withValues(alpha: 0.55),
          palette.surfaceHighest.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTRB(cx - 8, topY, cx + 8, bottomY))
      ..style = PaintingStyle.fill;

    canvas.drawPath(shaft, shaftPaint);

    final edge = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(shaft, edge);

    final counter = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, bottomY + 3), width: 16, height: 10),
      const Radius.circular(5),
    );
    canvas.drawRRect(
      counter,
      Paint()
        ..color = palette.surfaceHighest.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill,
    );

    // Highlight line
    canvas.drawLine(
      Offset(cx, topY + 32),
      Offset(cx, cy + 2),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant QiblaNeedlePainter oldDelegate) =>
      oldDelegate.needleExtent != needleExtent || oldDelegate.palette != palette;
}

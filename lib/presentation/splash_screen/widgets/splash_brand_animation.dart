import 'dart:math' as math;

import 'package:fitness_app/utils/managers/app_font.dart';
import 'package:fitness_app/utils/managers/color_manager.dart';
import 'package:flutter/material.dart';

/// "The Lift" — the animated Gym Buddy brand moment shown on the splash screen.
///
/// A barbell is drawn in code (no image assets), plates slide on from both
/// sides, the bar is lifted overhead, a ripple rolls across the floor and the
/// wordmark + tagline settle in underneath.
///
/// * [intro] drives the one-shot sequence (0 → 1).
/// * [idle] drives a gentle looping "breathing" glow and the progress line
///   shown while the app is still resolving where to go next.
///
/// The widget only paints; it contains no navigation or timing logic so it can
/// be tested and previewed in isolation. It deliberately avoids ScreenUtil so
/// it works before the app's responsive scaling is initialised.
class SplashBrandAnimation extends StatelessWidget {
  const SplashBrandAnimation({
    super.key,
    required this.intro,
    this.idle = const AlwaysStoppedAnimation<double>(0),
    this.showProgress = true,
  });

  /// Always-dark brand background (matches the native launch screen).
  static const Color background = Color(0xFF0A1C22);

  static const String name = 'Gym Buddy';
  static const String tagline = 'Train smarter. Every rep counts.';

  final Animation<double> intro;
  final Animation<double> idle;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final canvasWidth = math.min(width * 0.72, 320.0);

    return Semantics(
      container: true,
      label: '$name. $tagline',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([intro, idle]),
          builder: (context, _) {
            final t = intro.value;
            final textIn = _seg(t, 0.55, 0.80, Curves.easeOutCubic);
            final taglineIn = _seg(t, 0.70, 0.92, Curves.easeOutCubic);
            final progressIn = _seg(t, 0.85, 1.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: canvasWidth,
                  height: canvasWidth * 0.6,
                  child: CustomPaint(
                    painter: _BarbellPainter(progress: t, idle: idle.value),
                  ),
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: textIn,
                  child: Transform.translate(
                    offset: Offset(0, (1 - textIn) * 14),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Gym ',
                              style: TextStyle(color: Colors.white),
                            ),
                            TextSpan(
                              text: 'Buddy',
                              style: TextStyle(color: ColorManager.primary),
                            ),
                          ],
                        ),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: taglineIn,
                  child: Transform.translate(
                    offset: Offset(0, (1 - taglineIn) * 10),
                    child: Text(
                      tagline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: AppType.body,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Opacity(
                  opacity: showProgress ? progressIn : 0,
                  child: _ProgressLine(position: idle.value),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Maps [t] from the [a]..[b] window of the timeline into 0..1 with [curve].
double _seg(double t, double a, double b, [Curve curve = Curves.linear]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.position});

  /// 0..1 loop position of the travelling highlight.
  final double position;

  @override
  Widget build(BuildContext context) {
    const width = 120.0;
    const segment = 44.0;
    final eased = Curves.easeInOut.transform(position);
    return SizedBox(
      width: width,
      height: 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
            ),
            Positioned(
              left: -segment + (width + segment) * eased,
              width: segment,
              top: 0,
              bottom: 0,
              child: const ColoredBox(color: ColorManager.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Plate {
  const _Plate(this.offset, this.width, this.height, this.color, this.start);

  /// Distance from the centre as a fraction of the canvas width.
  final double offset;
  final double width;
  final double height;
  final Color color;

  /// When this plate starts sliding in (timeline fraction).
  final double start;
}

class _BarbellPainter extends CustomPainter {
  _BarbellPainter({required this.progress, required this.idle});

  final double progress;
  final double idle;

  static const _plates = <_Plate>[
    _Plate(0.20, 0.065, 0.62, ColorManager.primary, 0.10),
    _Plate(0.275, 0.050, 0.46, ColorManager.primaryDark, 0.17),
    _Plate(0.335, 0.040, 0.32, Color(0xFFBFF3E8), 0.24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final baseY = h * 0.66;

    final lift = _seg(progress, 0.32, 0.60, Curves.easeOutBack);
    final barY = baseY - h * 0.30 * lift;

    _paintGlow(canvas, size, Offset(cx, barY));
    _paintRipple(canvas, size, Offset(cx, baseY + h * 0.06));
    _paintBar(canvas, size, barY);

    for (final plate in _plates) {
      _paintPlatePair(canvas, size, barY, plate);
    }
    _paintCollars(canvas, size, barY);
  }

  void _paintGlow(Canvas canvas, Size size, Offset center) {
    final glowIn = _seg(progress, 0.32, 0.62, Curves.easeOut);
    if (glowIn <= 0) return;
    final breathe = 0.5 + 0.5 * math.sin(idle * 2 * math.pi);
    final radius = size.width * (0.55 + 0.03 * breathe);
    final alpha = (0.30 * glowIn) + (0.05 * breathe * glowIn);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          ColorManager.primary.withValues(alpha: alpha),
          ColorManager.primary.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _paintRipple(Canvas canvas, Size size, Offset center) {
    final t = _seg(progress, 0.55, 0.85, Curves.easeOut);
    if (t <= 0 || t >= 1) return;
    final r = size.width * (0.15 + 0.35 * t);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ColorManager.primary.withValues(alpha: 0.5 * (1 - t));
    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2, height: r * 0.7),
      paint,
    );
  }

  void _paintBar(Canvas canvas, Size size, double barY) {
    final draw = _seg(progress, 0.05, 0.30, Curves.easeOut);
    if (draw <= 0) return;
    final w = size.width;
    final half = w * 0.46 * draw;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.022
      ..color = const Color(0xFFDFF7F1);
    canvas.drawLine(
      Offset(w / 2 - half, barY),
      Offset(w / 2 + half, barY),
      paint,
    );
  }

  void _paintPlatePair(Canvas canvas, Size size, double barY, _Plate plate) {
    final t = _seg(progress, plate.start, plate.start + 0.22, Curves.easeOutCubic);
    if (t <= 0) return;
    final w = size.width;
    final h = size.height;
    final slide = (1 - t) * w * 0.25;
    final paint = Paint()
      ..color = plate.color.withValues(alpha: t.clamp(0.0, 1.0));
    final radius = Radius.circular(w * plate.width * 0.35);

    for (final side in const [-1.0, 1.0]) {
      final x = w / 2 + side * (w * plate.offset + slide);
      final rect = Rect.fromCenter(
        center: Offset(x, barY),
        width: w * plate.width,
        height: h * plate.height,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    }
  }

  void _paintCollars(Canvas canvas, Size size, double barY) {
    final t = _seg(progress, 0.24, 0.46, Curves.easeOut);
    if (t <= 0) return;
    final w = size.width;
    final paint = Paint()
      ..color = const Color(0xFFDFF7F1).withValues(alpha: t);
    for (final side in const [-1.0, 1.0]) {
      final rect = Rect.fromCenter(
        center: Offset(w / 2 + side * w * 0.385, barY),
        width: w * 0.02,
        height: w * 0.05,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(w * 0.006)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarbellPainter old) =>
      old.progress != progress || old.idle != idle;
}

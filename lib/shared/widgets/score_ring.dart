import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Güvenlik skoru halka grafiği
class ScoreRing extends StatefulWidget {
  final int score;
  final double size;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 140,
  });

  @override
  State<ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<ScoreRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = Tween<double>(begin: 0, end: widget.score / 100)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ScoreRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getScoreColor(int score) {
    if (score <= 40) return AppColors.danger;
    if (score <= 70) return AppColors.warning;
    return AppColors.safe;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(widget.score);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan halka
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: AppColors.backgroundBorder.withValues(alpha: 0.3),
                  strokeWidth: 10,
                ),
              ),
              // İlerleme halka
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: _animation.value,
                  color: color,
                  strokeWidth: 10,
                  hasShadow: true,
                ),
              ),
              // Skor metni
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${((_animation.value) * 100).round()}',
                    style: TextStyle(
                      fontSize: widget.size * 0.28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: widget.size * 0.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Ring painter
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool hasShadow;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    this.hasShadow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    if (hasShadow) {
      final shadowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        shadowPaint,
      );
    }

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

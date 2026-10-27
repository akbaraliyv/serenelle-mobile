import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chat_screen.dart';

class EnchantedOrbScreen extends StatefulWidget {
  final bool returnToChatOnClose;
  const EnchantedOrbScreen({super.key, this.returnToChatOnClose = false});

  @override
  State<EnchantedOrbScreen> createState() => _EnchantedOrbScreenState();
}

class _EnchantedOrbScreenState extends State<EnchantedOrbScreen>
    with TickerProviderStateMixin {
  late AnimationController _idleController;
  late AnimationController _pulseController;
  late AnimationController _burstController;
  late Animation<double> _burstAnimation;

  // Interactive Drag & Tilt
  Offset _orbOffset = Offset.zero;
  bool _isOpening = false;

  // Stardust Particles inside the orb
  final List<_OrbParticle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // 1. Idle breathing & particle orbiting animation (continuous)
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();

    // 2. Heartbeat pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // 3. Supernova burst animation
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _burstAnimation = CurvedAnimation(
      parent: _burstController,
      curve: Curves.easeInOutCubic,
    );

    // Generate 75 cosmic particles
    for (int i = 0; i < 75; i++) {
      _particles.add(_OrbParticle(
        radius: _random.nextDouble() * 95 + 10,
        angle: _random.nextDouble() * math.pi * 2,
        speed: (_random.nextDouble() * 0.8 + 0.3) * (_random.nextBool() ? 1 : -1),
        size: _random.nextDouble() * 3.5 + 1.2,
        color: i % 3 == 0
            ? const Color(0xFFC4B8E9)
            : (i % 3 == 1
                ? const Color(0xFF8D829F)
                : const Color(0xFFC89579)),
        verticalRatio: _random.nextDouble() * 0.7 + 0.3,
      ));
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _pulseController.dispose();
    _burstController.dispose();
    super.dispose();
  }

  void _triggerSupernova() async {
    if (_isOpening) return;
    _isOpening = true;
    HapticFeedback.mediumImpact();
    await _burstController.forward();
    if (!mounted) return;

    if (widget.returnToChatOnClose) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (_, __, ___) => const ChatScreen(),
          transitionsBuilder: (_, animation, __, child) {
            final eased = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: eased,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1).animate(eased),
                child: child,
              ),
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbSize = math.min(size.width * 0.78, 330.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF050509),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Cosmic Background Nebula
          AnimatedBuilder(
            animation: _idleController,
            builder: (context, _) {
              final val = _idleController.value * 2 * math.pi;
              return CustomPaint(
                painter: _CosmicBackgroundPainter(
                  pulseValue: _pulseController.value,
                  angle: val,
                ),
              );
            },
          ),

          // One tap opens the aperture; dragging only repositions the lens.
          Center(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _orbOffset += details.delta * 0.35;
                  _orbOffset = Offset(
                    _orbOffset.dx.clamp(-40.0, 40.0),
                    _orbOffset.dy.clamp(-40.0, 40.0),
                  );
                });
              },
              onPanEnd: (_) {
                setState(() {
                  _orbOffset = Offset.zero;
                });
              },
              onTap: _triggerSupernova,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _idleController,
                  _pulseController,
                  _burstAnimation,
                ]),
                builder: (context, _) {
                  return Transform.translate(
                    offset: _orbOffset,
                    child: SizedBox(
                      width: orbSize,
                      height: orbSize,
                      child: CustomPaint(
                        painter: _EnchantedOrbPainter(
                          time: _idleController.value * 2 * math.pi,
                          pulse: _pulseController.value,
                          burst: _burstAnimation.value,
                          charge: 0,
                          particles: _particles,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: math.max(30.0, bottomInset + 18),
            child: IgnorePointer(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 28, height: 1, color: const Color(0x668D829F)),
                  const SizedBox(height: 11),
                  const Text(
                    'TAP TO ENTER',
                    style: TextStyle(
                      color: Color(0xFF9B96A8),
                      fontSize: 9,
                      letterSpacing: 2.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbParticle {
  final double radius;
  final double angle;
  final double speed;
  final double size;
  final Color color;
  final double verticalRatio;

  _OrbParticle({
    required this.radius,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.verticalRatio,
  });
}

class _CosmicBackgroundPainter extends CustomPainter {
  final double pulseValue;
  final double angle;

  _CosmicBackgroundPainter({
    required this.pulseValue,
    required this.angle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width * (0.5 + math.cos(angle) * 0.055),
      size.height * (0.5 + math.sin(angle) * 0.035),
    );

    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x354A3F70), const Color(0x506F578D), pulseValue)!,
          const Color(0x152F3548),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.75));

    canvas.drawCircle(center, size.width * 0.75, nebulaPaint);
  }

  @override
  bool shouldRepaint(covariant _CosmicBackgroundPainter oldDelegate) => true;
}

class _EnchantedOrbPainter extends CustomPainter {
  final double time;
  final double pulse;
  final double burst;
  final double charge;
  final List<_OrbParticle> particles;

  _EnchantedOrbPainter({
    required this.time,
    required this.pulse,
    required this.burst,
    required this.charge,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.44;

    final currentRadius = baseRadius * (1.0 + charge * 0.15) * (1.0 + burst * 4.5);
    final alphaMultiplier = (1.0 - burst).clamp(0.0, 1.0);

    if (alphaMultiplier <= 0) return;

    // 1. Outer Ethereal Aurora Glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x668E7CC7).withOpacity(0.38 * alphaMultiplier),
          const Color(0x335D526D).withOpacity(0.18 * alphaMultiplier),
          Colors.transparent,
        ],
        stops: const [0.6, 0.85, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius * 1.4));

    canvas.drawCircle(center, currentRadius * 1.4, glowPaint);

    // 2. Crystal Sphere Inner Liquid Depth
    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          const Color(0xFF2A243A).withOpacity(0.9 * alphaMultiplier),
          const Color(0xFF13121C).withOpacity(0.97 * alphaMultiplier),
          const Color(0xFF08090D).withOpacity(0.99 * alphaMultiplier),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, spherePaint);

    // 3. Orbiting Stardust Particles inside the sphere
    for (final p in particles) {
      final currentAngle = p.angle + time * p.speed + (charge * 5.0);
      final r = (p.radius * (currentRadius / baseRadius)).clamp(5.0, currentRadius * 0.85);

      final px = center.dx + r * math.cos(currentAngle);
      final py = center.dy + r * math.sin(currentAngle) * p.verticalRatio;

      final pPaint = Paint()
        ..color = p.color.withOpacity(alphaMultiplier)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

      canvas.drawCircle(Offset(px, py), p.size * (1.0 + charge * 0.5), pPaint);
    }

    // 4. Abstract optical aperture, avoiding a heart-like twin-ring silhouette.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + charge * 2.0
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFC5B7EA).withOpacity(alphaMultiplier),
          const Color(0xFF8D829F).withOpacity(alphaMultiplier),
          const Color(0xFFC89579).withOpacity(alphaMultiplier),
          const Color(0xFFC5B7EA).withOpacity(alphaMultiplier),
        ],
        transform: GradientRotation(time),
      ).createShader(Rect.fromCircle(center: center, radius: 45));

    canvas.drawCircle(center, currentRadius * 0.2, ringPaint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(time * 0.22);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: currentRadius * 0.52, height: currentRadius * 0.3),
      ringPaint..strokeWidth = 1.1 + charge * 0.8,
    );
    canvas.restore();

    // 5. Crystal Specular Glare / Highlight (Upper-Left Reflection)
    final glarePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.45, -0.45),
        colors: [
          Colors.white.withOpacity(0.45 * alphaMultiplier),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.45],
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius * 0.9));

    canvas.drawCircle(center, currentRadius, glarePaint);

    // 6. Crystal Rim Border
    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 + charge * 2.5
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFB9AFE0).withOpacity(0.82 * alphaMultiplier),
          const Color(0xFF7F718E).withOpacity(0.72 * alphaMultiplier),
          const Color(0xFFC89579).withOpacity(0.66 * alphaMultiplier),
          const Color(0xFFB9AFE0).withOpacity(0.82 * alphaMultiplier),
        ],
        transform: GradientRotation(-time * 0.6),
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, rimPaint);

    // 7. Shockwave ring if bursting
    if (burst > 0.0) {
      final shockwavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - burst) * 12.0
        ..color = const Color(0xFFC5B7EA).withOpacity((1.0 - burst).clamp(0.0, 1.0));

      canvas.drawCircle(center, currentRadius * 1.5 * burst, shockwavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnchantedOrbPainter oldDelegate) => true;
}

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
  bool _isCharging = false;
  double _chargeProgress = 0.0;

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
      duration: const Duration(milliseconds: 800),
    );

    _burstAnimation = CurvedAnimation(
      parent: _burstController,
      curve: Curves.easeOutExpo,
    );

    // Generate 75 cosmic particles
    for (int i = 0; i < 75; i++) {
      _particles.add(_OrbParticle(
        radius: _random.nextDouble() * 95 + 10,
        angle: _random.nextDouble() * math.pi * 2,
        speed: (_random.nextDouble() * 0.8 + 0.3) * (_random.nextBool() ? 1 : -1),
        size: _random.nextDouble() * 3.5 + 1.2,
        color: i % 3 == 0
            ? const Color(0xFFFF2A6D)
            : (i % 3 == 1
                ? const Color(0xFF00F2FE)
                : const Color(0xFFFFD700)),
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

  void _onChargeStart() {
    setState(() {
      _isCharging = true;
    });
    HapticFeedback.lightImpact();
    _startChargingLoop();
  }

  void _startChargingLoop() async {
    while (_isCharging && _chargeProgress < 1.0) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (!mounted || !_isCharging) break;
      setState(() {
        _chargeProgress = math.min(1.0, _chargeProgress + 0.045);
      });
      if (_chargeProgress > 0.3 && _chargeProgress < 0.38) {
        HapticFeedback.selectionClick();
      } else if (_chargeProgress > 0.7 && _chargeProgress < 0.78) {
        HapticFeedback.mediumImpact();
      }
    }

    if (_chargeProgress >= 1.0) {
      _triggerSupernova();
    }
  }

  void _onChargeEnd() {
    if (_chargeProgress < 1.0) {
      setState(() {
        _isCharging = false;
        _chargeProgress = 0.0;
        _orbOffset = Offset.zero;
      });
    }
  }

  void _triggerSupernova() async {
    HapticFeedback.heavyImpact();
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
            return FadeTransition(
              opacity: animation,
              child: child,
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

    return Scaffold(
      backgroundColor: const Color(0xFF030104), // Pure Deep OLED void
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

          // 2. Central Interactive 3D Crystal Orb (Touch or Tap to Open)
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
              onTapDown: (_) => _onChargeStart(),
              onTapUp: (_) {
                if (_chargeProgress < 0.25) {
                  // Direct tap also triggers burst cleanly
                  _triggerSupernova();
                } else {
                  _onChargeEnd();
                }
              },
              onTapCancel: () => _onChargeEnd(),
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
                          charge: _chargeProgress,
                          particles: _particles,
                        ),
                      ),
                    ),
                  );
                },
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
    final center = Offset(size.width * 0.5, size.height * 0.5);

    final nebulaPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(const Color(0x358A2387), const Color(0x50E91E63), pulseValue)!,
          const Color(0x1500F2FE),
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
          const Color(0x66FF2A6D).withOpacity(0.4 * alphaMultiplier),
          const Color(0x339C27B0).withOpacity(0.2 * alphaMultiplier),
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
          const Color(0xFF2E0854).withOpacity(0.85 * alphaMultiplier),
          const Color(0xFF130026).withOpacity(0.95 * alphaMultiplier),
          const Color(0xFF070010).withOpacity(0.98 * alphaMultiplier),
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

    // 4. Center Glowing Twin Rings (Ethereal Symbol)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + charge * 2.0
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFFF2A6D).withOpacity(alphaMultiplier),
          const Color(0xFF00F2FE).withOpacity(alphaMultiplier),
          const Color(0xFFFFD700).withOpacity(alphaMultiplier),
          const Color(0xFFFF2A6D).withOpacity(alphaMultiplier),
        ],
        transform: GradientRotation(time),
      ).createShader(Rect.fromCircle(center: center, radius: 45));

    final rOffset = 16.0;
    canvas.drawCircle(center.translate(-rOffset, 0), 22, ringPaint);
    canvas.drawCircle(center.translate(rOffset, 0), 22, ringPaint);

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
          const Color(0xFF00F2FE).withOpacity(0.8 * alphaMultiplier),
          const Color(0xFFFF2A6D).withOpacity(0.9 * alphaMultiplier),
          const Color(0xFFFFD700).withOpacity(0.7 * alphaMultiplier),
          const Color(0xFF00F2FE).withOpacity(0.8 * alphaMultiplier),
        ],
        transform: GradientRotation(-time * 0.6),
      ).createShader(Rect.fromCircle(center: center, radius: currentRadius));

    canvas.drawCircle(center, currentRadius, rimPaint);

    // 7. Shockwave ring if bursting
    if (burst > 0.0) {
      final shockwavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1.0 - burst) * 12.0
        ..color = const Color(0xFFFF2A6D).withOpacity((1.0 - burst).clamp(0.0, 1.0));

      canvas.drawCircle(center, currentRadius * 1.5 * burst, shockwavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnchantedOrbPainter oldDelegate) => true;
}

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
      duration: const Duration(milliseconds: 900),
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
      await Future.delayed(const Duration(milliseconds: 30));
      if (!mounted || !_isCharging) break;
      setState(() {
        _chargeProgress = math.min(1.0, _chargeProgress + 0.035);
      });
      if (_chargeProgress > 0.3 && _chargeProgress < 0.35) {
        HapticFeedback.selectionClick();
      } else if (_chargeProgress > 0.7 && _chargeProgress < 0.75) {
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
          transitionDuration: const Duration(milliseconds: 700),
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

  void _skipToChat() {
    HapticFeedback.lightImpact();
    if (widget.returnToChatOnClose) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbSize = math.min(size.width * 0.76, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF030104), // Pure Deep OLED
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

          // 2. Top Header Title & Romantic Badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 28,
            left: 24,
            right: 24,
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFFFB2D1),
                      Color(0xFFE0C3FC),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'Azizbek & Serenelle',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0x33E91E63),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x55FF4081),
                      width: 1,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22FF4081),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 14),
                      SizedBox(width: 8),
                      Text(
                        '14,170 Xotira  •  2 Yillik Suhbat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Central Interactive 3D Enchanted Crystal Orb
          Center(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _orbOffset += details.delta * 0.4;
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
                if (_chargeProgress < 0.2) {
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

          // 4. Bottom Instructions & Direct Jump Pill
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 28,
            left: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: 0.7 + _pulseController.value * 0.3,
                      child: Text(
                        _isCharging
                            ? 'Xotiralar koinoti uyg\'onmoqda...'
                            : 'Sehrli kristall sharni bosing va ushlab turing ✨',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isCharging
                              ? const Color(0xFFFF4081)
                              : Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                InkWell(
                  onTap: _skipToChat,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.returnToChatOnClose ? 'Chatga qaytish' : 'To\'g\'ridan-to\'g\'ri chatga kirish',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white.withOpacity(0.8),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
    final center = Offset(size.width * 0.5, size.height * 0.48);

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

    // 4. Center Glowing Twin Rings (Infinity Sign of Azizbek & Serenelle)
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

    final rOffset = 18.0;
    canvas.drawCircle(center.translate(-rOffset, 0), 24, ringPaint);
    canvas.drawCircle(center.translate(rOffset, 0), 24, ringPaint);

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

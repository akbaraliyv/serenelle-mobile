import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JellySticker extends StatefulWidget {
  final String text;
  final bool isMe;

  const JellySticker({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  State<JellySticker> createState() => _JellyStickerState();
}

class _JellyStickerState extends State<JellySticker>
    with SingleTickerProviderStateMixin {
  late AnimationController _wobbleController;

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _wobbleController.dispose();
    super.dispose();
  }

  void _triggerJellyBounce() {
    HapticFeedback.lightImpact();
    _wobbleController.reset();
    _wobbleController.forward();
  }

  Color _getAuraColor(String text) {
    if (text.contains('🗿')) {
      return const Color(0x338A9CBA);
    } else if (text.contains('❤️') || text.contains('🥰')) {
      return const Color(0x33C88C9C);
    } else if (text.contains('🔥')) {
      return const Color(0x33C98265);
    } else if (text.contains('😂') || text.contains('🤣')) {
      return const Color(0x33D4B36E);
    } else if (text.contains('✅')) {
      return const Color(0x337FAE98);
    }
    return const Color(0x22B8A8E0);
  }

  @override
  Widget build(BuildContext context) {
    final auraColor = _getAuraColor(widget.text);
    final count = widget.text.runes.length;
    final double fontSize = count <= 2 ? 52.0 : (count <= 4 ? 44.0 : 38.0);

    return GestureDetector(
      onTap: _triggerJellyBounce,
      child: AnimatedBuilder(
        animation: _wobbleController,
        builder: (context, child) {
          final t = _wobbleController.value;
          // Spring damped sine wave wobble
          final decay = math.exp(-t * 4.0);
          final wave = math.sin(t * math.pi * 3.5);
          final scaleX = 1.0 + (0.24 * wave * decay);
          final scaleY = 1.0 - (0.18 * wave * decay);

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: auraColor,
                blurRadius: 28,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.15,
              shadows: const [
                Shadow(
                  color: Color(0x77000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
                Shadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

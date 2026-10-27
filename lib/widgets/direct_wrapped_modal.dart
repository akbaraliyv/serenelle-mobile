import 'package:flutter/material.dart';

class DirectWrappedModal extends StatelessWidget {
  final int messageCount;
  final int activeDays;
  final int photoCount;
  final int audioCount;

  const DirectWrappedModal({
    super.key,
    required this.messageCount,
    required this.activeDays,
    required this.photoCount,
    required this.audioCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF08080D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _RecapAtmospherePainter())),
          SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 13),
                Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 12, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ARCHIVE INDEX',
                          style: TextStyle(
                            color: Color(0xFFB9B4C8),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFFAAA7B8)),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                const Text(
                  'MESSAGES',
                  style: TextStyle(
                    color: Color(0xFFAAA7B8),
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFD5C9FF), Color(0xFFA99CCB), Color(0xFFC78E77)],
                  ).createShader(bounds),
                  child: Text(
                    _formatCount(messageCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 58,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  width: 42,
                  height: 1,
                  color: const Color(0x99B5A4D8),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Row(
                    children: [
                      Expanded(child: _Metric(value: '$activeDays', label: 'ACTIVE DAYS')),
                      const SizedBox(width: 9),
                      Expanded(child: _Metric(value: '$photoCount', label: 'PHOTOS')),
                      const SizedBox(width: 9),
                      Expanded(child: _Metric(value: '$audioCount', label: 'AUDIO')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int value) {
    final text = value.toString();
    final out = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) out.write(',');
      out.write(text[i]);
    }
    return out.toString();
  }
}

class _Metric extends StatelessWidget {
  final String value;
  final String label;

  const _Metric({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0x3812111B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0x338E83AA)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFFE8E2F1),
                fontSize: 22,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF9995A5),
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
}

class _RecapAtmospherePainter extends CustomPainter {
  const _RecapAtmospherePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF08080D));
    final upper = Rect.fromCircle(center: Offset(size.width * 0.32, size.height * 0.32), radius: size.width * 0.75);
    final lower = Rect.fromCircle(center: Offset(size.width * 0.92, size.height * 0.86), radius: size.width * 0.72);
    canvas.drawCircle(
      upper.center,
      upper.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x334D3F78), Color(0x16423860), Colors.transparent],
        ).createShader(upper),
    );
    canvas.drawCircle(
      lower.center,
      lower.width / 2,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x263A2635), Color(0x123E2B3A), Colors.transparent],
        ).createShader(lower),
    );
  }

  @override
  bool shouldRepaint(covariant _RecapAtmospherePainter oldDelegate) => false;
}

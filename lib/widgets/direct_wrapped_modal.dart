import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DirectWrappedModal extends StatefulWidget {
  const DirectWrappedModal({super.key});

  @override
  State<DirectWrappedModal> createState() => _DirectWrappedModalState();
}

class _DirectWrappedModalState extends State<DirectWrappedModal>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final int _totalSlides = 4;
  late AnimationController _progressController;
  Timer? _slideTimer;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _nextSlide();
        }
      });

    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _slideTimer?.cancel();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentIndex < _totalSlides - 1) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex++;
      });
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _prevSlide() {
    if (_currentIndex > 0) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex--;
      });
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Glow for current slide
          _buildBackgroundGradient(),

          // Slide Content
          SafeArea(
            child: Column(
              children: [
                // 1. Instagram Story Style Progress Bars
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: List.generate(_totalSlides, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: index < _currentIndex
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                )
                              : (index == _currentIndex
                                  ? AnimatedBuilder(
                                      animation: _progressController,
                                      builder: (_, __) {
                                        return FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _progressController.value,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : const SizedBox()),
                        ),
                      );
                    }),
                  ),
                ),

                // 2. Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'DIRECT WRAPPED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Azizbek & Serenelle',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // 3. Central Slide View
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final width = MediaQuery.of(context).size.width;
                      if (details.localPosition.dx < width * 0.35) {
                        _prevSlide();
                      } else {
                        _nextSlide();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildCurrentSlide(),
                    ),
                  ),
                ),

                // 4. Bottom Action
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Story posteri galereyaga saqlandi! ✨'),
                                backgroundColor: Color(0xFFE91E63),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55E91E63),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.share_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Story qilib ulashish',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildBackgroundGradient() {
    switch (_currentIndex) {
      case 0:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF311B92), Color(0xFF0F051D), Colors.black],
            ),
          ),
        );
      case 1:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF880E4F), Color(0xFF1D0312), Colors.black],
            ),
          ),
        );
      case 2:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF004D40), Color(0xFF021714), Colors.black],
            ),
          ),
        );
      default:
        return Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 1.1,
              colors: [Color(0xFF4A148C), Color(0xFF16042B), Colors.black],
            ),
          ),
        );
    }
  }

  Widget _buildCurrentSlide() {
    switch (_currentIndex) {
      case 0:
        return _buildMilestonesSlide();
      case 1:
        return _buildRatioSlide();
      case 2:
        return _buildEmojisSlide();
      case 3:
      default:
        return _buildNightOwlsSlide();
    }
  }

  // Slide 1: 14,170 Messages Milestone
  Widget _buildMilestonesSlide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 54),
        const SizedBox(height: 16),
        const Text(
          'Sizlar 2 yilda',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFF2A6D), Color(0xFFFFD700), Color(0xFF00F2FE)],
          ).createShader(bounds),
          child: const Text(
            '14,170',
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
        const Text(
          'ta xabar almashgansiz!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniBadge('95 kun', 'Faol kunlar'),
            const SizedBox(width: 14),
            _buildMiniBadge('67 ta', 'Rasmlar'),
            const SizedBox(width: 14),
            _buildMiniBadge('42 ta', 'Ovozli xabar'),
          ],
        ),
      ],
    );
  }

  // Slide 2: Balance Ratio (Serenelle vs Azizbek)
  Widget _buildRatioSlide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Kim ko\'proq yozgan?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 28),
        // Visual Bar
        Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Row(
              children: [
                Expanded(
                  flex: 59,
                  child: Container(
                    color: const Color(0xFFFF2A6D),
                    alignment: Alignment.center,
                    child: const Text(
                      '58.7%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 41,
                  child: Container(
                    color: const Color(0xFF00F2FE),
                    alignment: Alignment.center,
                    child: const Text(
                      '41.3%',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2A6D),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Serenelle',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Text(
                  '8,318 ta xabar',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00F2FE),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Azizbek',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Text(
                  '5,852 ta xabar',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Slide 3: Top Emojis
  Widget _buildEmojisSlide() {
    final emojis = [
      {'e': '😂', 'name': 'Kulgilar qiroli', 'count': '1,840 marta'},
      {'e': '❤️', 'name': 'Cheksiz mehr', 'count': '920 marta'},
      {'e': '🗿', 'name': 'Afsonaviy moyai', 'count': '480 marta'},
      {'e': '🥺', 'name': 'Erkalik', 'count': '310 marta'},
      {'e': '✨', 'name': 'Sehr', 'count': '240 marta'},
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Eng ko\'p ishlatilgan emojilar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        ...emojis.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              children: [
                Text(item['e']!, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 14),
                Text(
                  item['name']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  item['count']!,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Slide 4: Night Owls
  Widget _buildNightOwlsSlide() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.nightlight_round_rounded, color: Color(0xFF9C27B0), size: 54),
        const SizedBox(height: 16),
        const Text(
          'Tungi Rekordlar 🌙',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Soat 02:00 dan 05:00 gacha jami:',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 6),
        const Text(
          '1,420 ta xabar',
          style: TextStyle(
            color: Color(0xFFFF4081),
            fontSize: 42,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x339C27B0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x66BA68C8)),
          ),
          child: const Text(
            'Eng qizg\'in kun: 21-Fevral (1 kunda 460 ta xabar!) 🔥',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBadge(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x22FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

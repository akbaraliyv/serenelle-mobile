import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/search_bottom_sheet.dart';
import '../widgets/date_filter_modal.dart';
import '../widgets/image_viewer.dart';
import '../widgets/direct_wrapped_modal.dart';
import '../widgets/media_gallery_modal.dart';
import '../services/updater_service.dart';
import 'enchanted_orb_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _AuroraBackdrop extends StatefulWidget {
  final ValueListenable<Offset> touch;
  const _AuroraBackdrop({required this.touch});

  @override
  State<_AuroraBackdrop> createState() => _AuroraBackdropState();
}

class _AuroraBackdropState extends State<_AuroraBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_motion, widget.touch]),
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _AuroraPainter(_motion.value, widget.touch.value),
          ),
        ),
      );
}

class _AuroraPainter extends CustomPainter {
  final double phase;
  final Offset touch;
  const _AuroraPainter(this.phase, this.touch);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = const Color(0xFF05040A));
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x355D31BA), Color(0x3BB61A93), Color(0x35F16C51)],
          stops: [0, 0.52, 1],
        ).createShader(bounds),
    );
    final wave = math.sin(phase * math.pi * 2);
    final center = Offset(size.width * (0.5 + (touch.dx - 0.5) * 0.12),
        size.height * (0.48 + (touch.dy - 0.5) * 0.08));
    final colors = const [Color(0xFF5421A8), Color(0xFFB11A83), Color(0xFFFF654F)];
    for (var i = 0; i < 3; i++) {
      final c = Offset(center.dx + math.sin(wave + i * 2.1) * size.width * 0.16,
          size.height * (0.18 + i * 0.34) + math.cos(wave + i) * 24);
      final rect = Rect.fromCenter(center: c, width: size.width * 1.15, height: size.height * 0.62);
      final paint = Paint()
        ..shader = RadialGradient(colors: [colors[i].withOpacity(0.18), colors[i].withOpacity(0.045), Colors.transparent], stops: const [0, 0.48, 1])
            .createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 48);
      canvas.drawOval(rect, paint);
    }
    final starPaint = Paint()..color = Colors.white.withOpacity(0.26);
    for (var i = 0; i < 38; i++) {
      final x = ((i * 73 + 19) % 997) / 997 * size.width;
      final y = ((i * 137 + 41) % 991) / 991 * size.height;
      canvas.drawCircle(Offset(x + (touch.dx - .5) * 9, y + (touch.dy - .5) * 9), i % 7 == 0 ? 1.1 : .55, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.touch != touch;
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  List<ChatMessage> _messages = [];
  List<DateMeta> _dates = [];
  bool _isLoading = true;
  int? _highlightedId;

  // Dynamic Island Floating Date & Liquid Velocity Tilt
  String _currentFloatingDate = '';
  bool _isScrolling = false;
  Timer? _scrollEndTimer;
  double _scrollTilt = 0.0;
  double _lastScrollPixels = 0.0;
  final ValueNotifier<Offset> _ambientTouch = ValueNotifier(const Offset(0.5, 0.5));

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupScrollListener();
  }

  void _setupScrollListener() {
    _itemPositionsListener.itemPositions.addListener(() {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isNotEmpty && _messages.isNotEmpty) {
        int minIndex = positions
            .where((p) => p.itemTrailingEdge > 0)
            .map((p) => p.index)
            .fold(positions.first.index, math.min);

        if (minIndex >= 0 && minIndex < _messages.length) {
          final date = _messages[minIndex].dateFormatted;
          if (date != _currentFloatingDate || !_isScrolling) {
            setState(() {
              _currentFloatingDate = date;
              _isScrolling = true;
              _scrollTilt = 0.015; // Subtle 1 degree liquid velocity tilt
            });

            _scrollEndTimer?.cancel();
            _scrollEndTimer = Timer(const Duration(milliseconds: 900), () {
              if (mounted) {
                setState(() {
                  _isScrolling = false;
                  _scrollTilt = 0.0;
                });
              }
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollEndTimer?.cancel();
    _ambientTouch.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final messages = await DatabaseService.instance.getAllMessages();
    final dates = await DatabaseService.instance.getDates();

    if (mounted) {
      setState(() {
        _messages = messages;
        _dates = dates;
        _isLoading = false;
      });

      // Jump directly to the latest message (bottom) on startup
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_messages.isNotEmpty && _itemScrollController.isAttached) {
          _itemScrollController.jumpTo(index: _messages.length - 1);
        }
      });

      // Silently check for newer version on startup
      Future.delayed(const Duration(seconds: 2), () async {
        if (!mounted) return;
        final update = await UpdaterService.checkUpdate();
        if (update != null && mounted) {
          UpdaterService.showUpdatePrompt(context, update);
        }
      });
    }
  }

  void _scrollToIndex(int index, {int? highlightId}) {
    if (!_itemScrollController.isAttached || index < 0 || index >= _messages.length) return;

    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0.2, // Positions message near top 20% of viewport
    );

    if (highlightId != null) {
      setState(() => _highlightedId = highlightId);
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _highlightedId = null);
      });
    }
  }

  void _scrollToTop() {
    HapticFeedback.lightImpact();
    if (_itemScrollController.isAttached && _messages.isNotEmpty) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToBottom() {
    HapticFeedback.lightImpact();
    if (_itemScrollController.isAttached && _messages.isNotEmpty) {
      _itemScrollController.scrollTo(
        index: _messages.length - 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _openSearch() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchBottomSheet(
        allMessages: _messages,
        onSelectResult: (index, id) => _scrollToIndex(index, highlightId: id),
      ),
    );
  }

  void _openDateFilter() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateFilterModal(
        dates: _dates,
        onSelectDate: (firstIndex, firstId) => _scrollToIndex(firstIndex, highlightId: firstId),
      ),
    );
  }

  void _openDirectWrapped() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DirectWrappedModal(),
    );
  }

  void _openMediaGallery() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaGalleryModal(
        allMessages: _messages,
        onSelectMessage: (index, id) => _scrollToIndex(index, highlightId: id),
      ),
    );
  }

  void _jumpToRandomMemory() {
    if (_messages.isEmpty) return;
    HapticFeedback.heavyImpact();
    final randomIdx = math.Random().nextInt(_messages.length);
    final msg = _messages[randomIdx];
    _scrollToIndex(randomIdx, highlightId: msg.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎲', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${msg.dateFormatted} lahzasiga sakraldi!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE91E63),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openEnchantedOrb() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const EnchantedOrbScreen(returnToChatOnClose: true),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  void _manualCheckUpdate() async {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yangilanishlar tekshirilmoqda...'),
        duration: Duration(seconds: 1),
      ),
    );
    final update = await UpdaterService.checkUpdate();
    if (!mounted) return;
    if (update != null) {
      UpdaterService.showUpdatePrompt(context, update);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sizda eng so\'nggi versiya (v1.0.3) o\'rnatilgan!'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030104), // Pure OLED dark
      appBar: _buildInstagramHeader(),
      body: Listener(
        onPointerMove: (event) {
          final size = MediaQuery.sizeOf(context);
          _ambientTouch.value = Offset(
            (event.position.dx / size.width).clamp(0.0, 1.0).toDouble(),
            (event.position.dy / size.height).clamp(0.0, 1.0).toDouble(),
          );
        },
        child: Stack(
        children: [
          Positioned.fill(child: _AuroraBackdrop(touch: _ambientTouch)),

          // Main 120Hz Virtualized List with Liquid Velocity Tilt
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF2A6D)),
                  SizedBox(height: 16),
                  Text(
                    '14,170 ta xabar tayyorlanmoqda...',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification && notification.metrics.axis == Axis.vertical) {
                  final delta = notification.metrics.pixels - _lastScrollPixels;
                  _lastScrollPixels = notification.metrics.pixels;
                  final tilt = (delta / 1800).clamp(-0.012, 0.012).toDouble();
                  if ((tilt - _scrollTilt).abs() > 0.001) {
                    setState(() => _scrollTilt = tilt);
                  }
                }
                return false;
              },
              child: ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _messages.length,
              padding: const EdgeInsets.only(top: 8, bottom: 85),
              itemBuilder: (context, index) {
                final message = _messages[index];

                final bool showDateHeader = index == 0 ||
                    _messages[index - 1].isoDate != message.isoDate;

                return Column(
                  children: [
                    if (showDateHeader) _buildDateDivider(message.dateFormatted),
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateX(_scrollTilt * (message.isMe ? 1 : -1)),
                      child: ChatBubble(
                        message: message,
                        isHighlighted: message.id == _highlightedId,
                        onOpenImage: message.imageName != null
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ImageViewerScreen(
                                      imageName: message.imageName!,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                );
              },
              ),
            ),

          // Floating Dynamic Island Date Capsule (Visible while scrolling)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isScrolling && _currentFloatingDate.isNotEmpty ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xE61E1428),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0x66FF2A6D),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Color(0x33FF2A6D),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFFFF4081),
                        size: 13,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _currentFloatingDate,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Safe-Area Jump Dock
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: _buildFloatingJumpDock(),
          ),
        ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildInstagramHeader() {
    return AppBar(
      backgroundColor: const Color(0xE60D0914), // Glassmorphic header
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 8,
      title: Row(
        children: [
          // Story Gradient Avatar (Tap to open Direct Wrapped 2025!)
          GestureDetector(
            onTap: _openDirectWrapped,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFBAA47), Color(0xFFD91A46), Color(0xFFA60F93)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66D91A46),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF140E1B),
                ),
                alignment: Alignment.center,
                child: const Text(
                  's',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Name, Verification Badge & Wrapped trigger
          Expanded(
            child: GestureDetector(
              onTap: _openDirectWrapped,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'serenelle.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 13),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE91E63), Color(0xFFFF9800)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Wrapped ✨',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '_sserenelle • 14,170 ta xabar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // 🔮 Sehrli Kristall Shar (Reopen Enchanted Orb)
        IconButton(
          icon: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFFD700), size: 21),
          tooltip: 'Sehrli Kristall Shar',
          onPressed: _openEnchantedOrb,
        ),
        // 🎲 Tasodifiy Xotira Ruletkasi (Random Memory Roulette)
        IconButton(
          icon: const Icon(Icons.casino_rounded, color: Color(0xFF00F2FE), size: 21),
          tooltip: 'Tasodifiy Lahza Ruletkasi',
          onPressed: _jumpToRandomMemory,
        ),
        // 📸 Mediateka & Xotiralar (No bottom bar clutter!)
        IconButton(
          icon: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF80AB), size: 21),
          tooltip: 'Mediateka',
          onPressed: _openMediaGallery,
        ),
        // 📅 Calendar Date Filter
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 21),
          tooltip: 'Sanalar filtri',
          onPressed: _openDateFilter,
        ),
        // 🔍 FTS Search
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 21),
          tooltip: 'Qidirish',
          onPressed: _openSearch,
        ),
      ],
    );
  }

  Widget _buildDateDivider(String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Text(
        date,
        style: TextStyle(
          color: Colors.white.withOpacity(0.65),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFloatingJumpDock() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xE61A1322),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0x40FF2A6D), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x33FF2A6D),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Jump To Top Button
            InkWell(
              onTap: _scrollToTop,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: Color(0xFFFF4081), size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Eng Tepaga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              width: 1,
              height: 18,
              color: Colors.white.withOpacity(0.18),
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Jump To Bottom Button
            InkWell(
              onTap: _scrollToBottom,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: Color(0xFFFF4081), size: 16),
                    SizedBox(width: 5),
                    Text(
                      'Eng Pastga',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

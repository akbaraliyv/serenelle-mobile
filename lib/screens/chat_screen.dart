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

enum _ArchiveAction { search, dates, media, random, recap, portal, top, latest, update }

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
      builder: (_) => DirectWrappedModal(
        messageCount: _messages.length,
        activeDays: _dates.length,
        photoCount: _messages.where((message) => message.imageName != null).length,
        audioCount: _messages.where((message) => message.audioName != null).length,
      ),
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
    HapticFeedback.selectionClick();
    final randomIdx = math.Random().nextInt(_messages.length);
    final msg = _messages[randomIdx];
    _scrollToIndex(randomIdx, highlightId: msg.id);
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
          content: Text('Eng so\'nggi versiya o\'rnatilgan.'),
          backgroundColor: const Color(0xFF17161E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleArchiveAction(_ArchiveAction action) {
    switch (action) {
      case _ArchiveAction.search:
        _openSearch();
        break;
      case _ArchiveAction.dates:
        _openDateFilter();
        break;
      case _ArchiveAction.media:
        _openMediaGallery();
        break;
      case _ArchiveAction.random:
        _jumpToRandomMemory();
        break;
      case _ArchiveAction.recap:
        _openDirectWrapped();
        break;
      case _ArchiveAction.portal:
        _openEnchantedOrb();
        break;
      case _ArchiveAction.top:
        _scrollToTop();
        break;
      case _ArchiveAction.latest:
        _scrollToBottom();
        break;
      case _ArchiveAction.update:
        _manualCheckUpdate();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050509),
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
                  CircularProgressIndicator(color: Color(0xFFB8A8E0)),
                  SizedBox(height: 16),
                  Text(
                    'OPENING ARCHIVE',
                    style: TextStyle(color: Color(0xFFAAA7B8), fontSize: 10, letterSpacing: 2.2),
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
              padding: const EdgeInsets.only(top: 8, bottom: 20),
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
                      color: const Color(0x667C6F9A),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x55000000),
                        blurRadius: 16,
                        offset: Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Color(0x33897BA4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: Color(0xFFC3B5E0),
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

        ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildInstagramHeader() {
    return AppBar(
      backgroundColor: const Color(0xE6050509),
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          _buildPortalMark(size: 26),
          const SizedBox(width: 12),
          const Text('DIRECT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 2.4)),
          const SizedBox(width: 10),
          const SizedBox(height: 20, child: VerticalDivider(width: 1, color: Color(0x558C86A7))),
          const SizedBox(width: 9),
          const Text('ARCHIVE', style: TextStyle(color: Color(0xFFAAA7B8), fontSize: 9, letterSpacing: 2.1)),
        ],
      ),
      actions: [
        PopupMenuButton<_ArchiveAction>(
          tooltip: 'Archive actions',
          icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFFE7E4F0), size: 24),
          color: const Color(0xFF111018),
          onSelected: _handleArchiveAction,
          itemBuilder: (_) => const [
            PopupMenuItem(value: _ArchiveAction.search, child: Text('Qidiruv')),
            PopupMenuItem(value: _ArchiveAction.dates, child: Text('Sana bo‘yicha')),
            PopupMenuItem(value: _ArchiveAction.media, child: Text('Media')),
            PopupMenuItem(value: _ArchiveAction.random, child: Text('Tasodifiy xabar')),
            PopupMenuItem(value: _ArchiveAction.recap, child: Text('Arxiv ko‘rsatkichi')),
            PopupMenuItem(value: _ArchiveAction.top, child: Text('Boshiga o‘tish')),
            PopupMenuItem(value: _ArchiveAction.latest, child: Text('Eng yangisiga o‘tish')),
            PopupMenuItem(value: _ArchiveAction.portal, child: Text('Kirish portali')),
            PopupMenuItem(value: _ArchiveAction.update, child: Text('Yangilanishni tekshirish')),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPortalMark({required double size}) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PortalMarkPainter()),
      );

  Widget _buildDateDivider(String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x338E83AA)),
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

}

class _PortalMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shader = const SweepGradient(
      colors: [Color(0xFF8B78D6), Color(0xFFC5C3D9), Color(0xFFB68D74), Color(0xFF8B78D6)],
    ).createShader(Offset.zero & size);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.25..shader = shader;
    canvas.drawOval(Rect.fromCenter(center: center, width: size.width * 0.56, height: size.height * 0.88), paint);
    canvas.drawOval(Rect.fromCenter(center: center, width: size.width * 0.9, height: size.height * 0.54), paint);
  }

  @override
  bool shouldRepaint(covariant _PortalMarkPainter oldDelegate) => false;
}

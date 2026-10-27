import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/search_bottom_sheet.dart';
import '../widgets/date_filter_modal.dart';
import '../widgets/image_viewer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  List<ChatMessage> _messages = [];
  List<DateMeta> _dates = [];
  bool _isLoading = true;
  int? _highlightedId;

  @override
  void initState() {
    super.initState();
    _loadData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030104), // Pure OLED dark
      appBar: _buildInstagramHeader(),
      body: Stack(
        children: [
          // Background subtle ambient glows
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x22E91E63), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x20880E4F), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main 120Hz Virtualized List
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
            ScrollablePositionedList.builder(
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: _messages.length,
              padding: const EdgeInsets.only(top: 8, bottom: 85),
              itemBuilder: (context, index) {
                final message = _messages[index];

                // Check if date changed from previous message
                final bool showDateHeader = index == 0 ||
                    _messages[index - 1].isoDate != message.isoDate;

                return Column(
                  children: [
                    if (showDateHeader) _buildDateDivider(message.dateFormatted),
                    ChatBubble(
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
                  ],
                );
              },
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
    );
  }

  PreferredSizeWidget _buildInstagramHeader() {
    return AppBar(
      backgroundColor: const Color(0xE60D0914), // Glassmorphic header
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 10,
      title: Row(
        children: [
          // Story Gradient Avatar
          Container(
            padding: const EdgeInsets.all(2.2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFBAA47), Color(0xFFD91A46), Color(0xFFA60F93)],
              ),
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
          const SizedBox(width: 10),

          // Name & Verification Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'serenelle.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 14),
                  ],
                ),
                Text(
                  '_sserenelle • 14,170 ta xabar',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
          tooltip: 'Sanalar filtri',
          onPressed: _openDateFilter,
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded, color: Colors.white),
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

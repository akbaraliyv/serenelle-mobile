import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import 'image_viewer.dart';

class MediaGalleryModal extends StatefulWidget {
  final List<ChatMessage> allMessages;
  final Function(int index, int id) onSelectMessage;

  const MediaGalleryModal({
    super.key,
    required this.allMessages,
    required this.onSelectMessage,
  });

  @override
  State<MediaGalleryModal> createState() => _MediaGalleryModalState();
}

class _MediaGalleryModalState extends State<MediaGalleryModal> {
  int _selectedTab = 0; // 0 = Photos, 1 = Audio notes
  late List<_MediaItem> _photos;
  late List<_MediaItem> _audios;

  @override
  void initState() {
    super.initState();
    _extractMedia();
  }

  void _extractMedia() {
    _photos = [];
    _audios = [];

    for (int i = 0; i < widget.allMessages.length; i++) {
      final msg = widget.allMessages[i];
      if (msg.imageName != null) {
        _photos.add(_MediaItem(
          index: i,
          message: msg,
          mediaPath: msg.imageName!,
        ));
      } else if (msg.audioName != null) {
        _audios.add(_MediaItem(
          index: i,
          message: msg,
          mediaPath: msg.audioName!,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0C0714),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Notch Handle
          const SizedBox(height: 12),
          Container(
            width: 42,
            height: 4.5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),

          // Title & Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.collections_rounded, color: Color(0xFFFF2A6D), size: 22),
                const SizedBox(width: 10),
                const Text(
                  'Mediateka & Xotiralar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Segmented Tabs: Photos vs Voice Notes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0x22FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Rasmlar (${_photos.length})',
                      isSelected: _selectedTab == 0,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = 0);
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildSegmentButton(
                      title: 'Ovozli (${_audios.length})',
                      isSelected: _selectedTab == 1,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTab = 1);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Main Media Grid / List
          Expanded(
            child: _selectedTab == 0 ? _buildPhotosGrid() : _buildAudioList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF2A6D) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x55FF2A6D),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
    if (_photos.isEmpty) {
      return const Center(
        child: Text(
          'Rasmlar mavjud emas',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, idx) {
        final item = _photos[idx];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
            widget.onSelectMessage(item.index, item.message.id);
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/media/photos/${item.mediaPath}',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0x33FFFFFF),
                    child: const Icon(Icons.image, color: Colors.white30),
                  ),
                ),
                // Subtle date gradient at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Text(
                      item.message.timeStr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAudioList() {
    if (_audios.isEmpty) {
      return const Center(
        child: Text(
          'Ovozli xabarlar mavjud emas',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _audios.length,
      itemBuilder: (context, idx) {
        final item = _audios[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0x33FF2A6D),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, color: Color(0xFFFF2A6D), size: 20),
            ),
            title: Text(
              item.message.senderName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${item.message.dateFormatted} • ${item.message.timeStr}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x22FF2A6D),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Chatda ko\'rish',
                style: TextStyle(
                  color: Color(0xFFFF4081),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              widget.onSelectMessage(item.index, item.message.id);
            },
          ),
        );
      },
    );
  }
}

class _MediaItem {
  final int index;
  final ChatMessage message;
  final String mediaPath;

  _MediaItem({
    required this.index,
    required this.message,
    required this.mediaPath,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import 'audio_player_bubble.dart';
import 'jelly_sticker.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isHighlighted;
  final VoidCallback? onOpenImage;

  const ChatBubble({
    super.key,
    required this.message,
    this.isHighlighted = false,
    this.onOpenImage,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isHighlighted
              ? const Color(0x33E91E63)
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Row containing Avatar (if them) and Bubble
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  // Partner Mini Avatar Ring
                  Container(
                    width: 26,
                    height: 26,
                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      's',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                // Main Bubble Content
                Flexible(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBubbleBody(context),

                      // Floating 3D Crystal Heart Reaction
                      if (message.reaction != null)
                        Positioned(
                          bottom: -9,
                          right: isMe ? null : -6,
                          left: isMe ? -6 : null,
                          child: _buildCrystalReactionBadge(message.reaction!),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Time stamp below bubble
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: isMe ? 0 : 36,
                right: isMe ? 6 : 0,
                bottom: message.reaction != null ? 8 : 2,
              ),
              child: Text(
                message.timeStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubbleBody(BuildContext context) {
    final isMe = message.isMe;

    // 1. Standalone 3D Animated Jelly Sticker (no bubble background)
    if (message.isStickerEmoji) {
      return JellySticker(
        text: message.text!,
        isMe: isMe,
      );
    }

    // 2. Animated GIF Sticker
    if (message.isGifMessage && message.extractedGifUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
            maxHeight: 250,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white12),
          ),
          child: Image.network(
            message.extractedGifUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 160,
                color: const Color(0x22FFFFFF),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF2A6D), strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: const Color(0x22FFFFFF),
              child: const Center(child: Icon(Icons.gif_rounded, size: 40, color: Colors.white38)),
            ),
          ),
        ),
      );
    }

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(19),
      topRight: const Radius.circular(19),
      bottomLeft: Radius.circular(isMe ? 19 : 5),
      bottomRight: Radius.circular(isMe ? 5 : 19),
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      decoration: BoxDecoration(
        borderRadius: bubbleRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMe
              ? const [Color(0x68D335A5), Color(0x588B35C8), Color(0x62F06C55)]
              : const [Color(0xAAE7D9FF), Color(0x448878A8), Color(0x778D658A)],
          stops: const [0, 0.52, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0x557F2B9C)
                : const Color(0x44000000),
            blurRadius: isMe ? 18 : 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: Container(
        decoration: BoxDecoration(
          color: isMe ? const Color(0x40130D20) : const Color(0xC908080D),
          borderRadius: bubbleRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isMe
                ? const [Color(0x2A381B42), Color(0x10200F2B)]
                : const [Color(0x402D2938), Color(0xB80A090F)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.replyText != null) _buildReplyQuote(),
            if (message.imageName != null) _buildPhotoAttachment(context),
            if (message.audioName != null)
              AudioPlayerBubble(audioName: message.audioName!, isMe: isMe),
            if (message.text != null && message.text!.isNotEmpty)
              SelectableText(
                message.text!,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFFF1EBF5),
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyQuote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: Color(0xFFFF4081), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replySender ?? 'Xabar',
            style: const TextStyle(
              color: Color(0xFFFF80AB),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyText!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAttachment(BuildContext context) {
    return GestureDetector(
      onTap: onOpenImage,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Image.asset(
          'assets/media/photos/${message.imageName}',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 160,
            color: Colors.grey.shade900,
            alignment: Alignment.center,
            child: const Icon(Icons.image, color: Colors.white30, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildCrystalReactionBadge(String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF26101D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF2A6D).withOpacity(0.55),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FF2A6D),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        emoji,
        style: const TextStyle(
          fontSize: 12,
          shadows: [
            Shadow(
              color: Color(0xFFFF2A6D),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

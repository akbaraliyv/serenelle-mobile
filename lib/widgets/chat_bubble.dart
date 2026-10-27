import 'dart:ui' as ui;
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
              ? const Color(0x337C6F9A)
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
                // Main Bubble Content
                Flexible(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildBubbleBody(context),

                      // A small node connects every message to the chamber's time spine.
                      Positioned(
                        top: 19,
                        left: isMe ? -17 : null,
                        right: isMe ? null : -17,
                        child: IgnorePointer(child: _buildTimeNode(isMe)),
                      ),

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
                left: isMe ? 0 : 4,
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
                  child: CircularProgressIndicator(color: Color(0xFFB8A8E0), strokeWidth: 2),
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
      topLeft: Radius.circular(isMe ? 24 : 7),
      topRight: Radius.circular(isMe ? 7 : 24),
      bottomLeft: Radius.circular(isMe ? 24 : 7),
      bottomRight: Radius.circular(isMe ? 7 : 24),
    );

    final glassSurface = ClipRRect(
      borderRadius: bubbleRadius,
      child: Stack(
        children: [
          Positioned.fill(
            child: isMe
                ? _ViewportLiquidGradient(radius: bubbleRadius)
                : const ColoredBox(color: Color(0x8808090E)),
          ),
          if (!isMe)
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                child: const ColoredBox(color: Color(0x440E0D15)),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isMe
                      ? const [Color(0x40FFFFFF), Color(0x06070710), Color(0x33160820)]
                      : const [Color(0x32FFFFFF), Color(0x080C0D14), Color(0x28000000)],
                  stops: const [0, 0.42, 1],
                ),
                border: Border.all(
                  color: isMe ? const Color(0xB9FFD7F3) : const Color(0x7D9187BE),
                  width: isMe ? 0.8 : 0.7,
                ),
                borderRadius: bubbleRadius,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 15,
            right: 15,
            child: IgnorePointer(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                  colors: isMe
                        ? const [Colors.transparent, Color(0xD6FFFFFF), Color(0xA4FF9CD7), Colors.transparent]
                        : const [Colors.transparent, Color(0xA69B93C4), Color(0x55FFFFFF), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.76,
      ),
      decoration: BoxDecoration(
        borderRadius: bubbleRadius,
        color: Colors.transparent,
        border: Border.all(
          color: isMe ? const Color(0xB9FFD7F3) : const Color(0x7D9187BE),
          width: isMe ? 0.8 : 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0x77521588)
                : const Color(0x70000000),
            blurRadius: isMe ? 22 : 18,
            offset: const Offset(0, 7),
          ),
          if (isMe)
            const BoxShadow(
              color: Color(0x55ED21AA),
              blurRadius: 20,
              spreadRadius: -3,
            )
          else
            const BoxShadow(
              color: Color(0x335D5A86),
              blurRadius: 14,
              spreadRadius: -4,
            ),
        ],
      ),
      padding: const EdgeInsets.all(1),
      child: ClipRRect(
        borderRadius: bubbleRadius,
        child: Stack(
          children: [
            Positioned.fill(child: glassSurface),
            Padding(
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
                        shadows: isMe
                            ? const [Shadow(color: Color(0x66420D41), blurRadius: 9)]
                            : const [Shadow(color: Color(0x66000000), blurRadius: 7)],
                      ),
                    ),
                ],
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
            left: BorderSide(color: Color(0xFFB6A9D7), width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replySender ?? 'Xabar',
            style: const TextStyle(
              color: Color(0xFFD0C5E5),
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
          color: const Color(0xFF18151F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFB6A9D7).withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x558F82B1),
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
              color: Color(0xFFB8A8E0),
              blurRadius: 6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeNode(bool isMe) {
    return SizedBox(
      width: 17,
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 13,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isMe
                      ? const [Color(0x00FF53B7), Color(0xB7FF53B7)]
                      : const [Color(0xA58A84B8), Color(0x008A84B8)],
                ),
              ),
            ),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMe ? const Color(0xFFFF72BD) : const Color(0xFFB1A7D1),
              boxShadow: [BoxShadow(color: isMe ? const Color(0xAAFF24A5) : const Color(0x778F86B6), blurRadius: 7)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Applies one viewport-aligned gradient to every outgoing bubble. As messages
/// scroll through the screen, the purple/magenta/coral bands travel through them.
class _ViewportLiquidGradient extends StatelessWidget {
  final BorderRadius radius;
  const _ViewportLiquidGradient({required this.radius});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) => ClipRRect(
        borderRadius: radius,
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final renderObject = context.findRenderObject();
            final globalTop = renderObject is RenderBox && renderObject.hasSize
                ? renderObject.localToGlobal(Offset.zero).dy
                : 0.0;
            final screenHeight = MediaQuery.sizeOf(context).height;
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF5C2EC6), Color(0xFFE10A9F), Color(0xFFFF7058)],
              stops: [0, 0.52, 1],
            ).createShader(
              Rect.fromLTWH(0, -globalTop, bounds.width, screenHeight),
            );
          },
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
  }
}

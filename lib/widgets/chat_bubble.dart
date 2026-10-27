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
      topLeft: const Radius.circular(19),
      topRight: const Radius.circular(19),
      bottomLeft: Radius.circular(isMe ? 19 : 5),
      bottomRight: Radius.circular(isMe ? 5 : 19),
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
                      ? const [Color(0x2AFFFFFF), Color(0x080A0710), Color(0x24160B14)]
                      : const [Color(0x22FFFFFF), Color(0x0DFFFFFF), Color(0x140A090F)],
                  stops: const [0, 0.42, 1],
                ),
                border: Border.all(
                  color: isMe ? const Color(0x99F6D8FF) : const Color(0x668F87A5),
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
                        ? const [Colors.transparent, Color(0xBFFFFFFF), Color(0x70F7B6D8), Colors.transparent]
                        : const [Colors.transparent, Color(0x668F87A5), Color(0x33FFFFFF), Colors.transparent],
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
          color: isMe ? const Color(0x99F6D8FF) : const Color(0x668F87A5),
          width: isMe ? 0.8 : 0.7,
        ),
        boxShadow: [
          BoxShadow(
            color: isMe
                ? const Color(0x665A1C73)
                : const Color(0x70000000),
            blurRadius: isMe ? 22 : 18,
            offset: const Offset(0, 7),
          ),
          if (isMe)
            const BoxShadow(
              color: Color(0x33F036A8),
              blurRadius: 15,
              spreadRadius: -3,
            )
          else
            const BoxShadow(
              color: Color(0x225F5875),
              blurRadius: 10,
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

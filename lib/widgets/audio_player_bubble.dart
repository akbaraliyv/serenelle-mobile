import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerBubble extends StatefulWidget {
  final String audioName;
  final bool isMe;

  const AudioPlayerBubble({
    super.key,
    required this.audioName,
    required this.isMe,
  });

  @override
  State<AudioPlayerBubble> createState() => _AudioPlayerBubbleState();
}

class _AudioPlayerBubbleState extends State<AudioPlayerBubble> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final duration = await _player.setAsset('assets/media/audio/${widget.audioName}');
      if (mounted && duration != null) {
        setState(() => _duration = duration);
      }
    } catch (_) {
      // Graceful fallback if asset file path differs
    }

    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
          }
        });
      }
    });

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause circle button
          GestureDetector(
            onTap: () {
              if (_isPlaying) {
                _player.pause();
              } else {
                _player.play();
              }
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4081), Color(0xFFE040FB)],
                ),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Waveform bars simulation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(24, (i) {
                    final progressRatio = _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0.0;
                    final isPlayed = (i / 24) <= progressRatio;
                    // Simulated waveform height pattern
                    final barHeights = [
                      8, 14, 20, 12, 24, 18, 10, 22, 16, 26, 12, 19,
                      22, 14, 25, 11, 16, 20, 14, 24, 18, 12, 16, 8
                    ];
                    return Container(
                      width: 2.4,
                      height: barHeights[i % barHeights.length].toDouble(),
                      decoration: BoxDecoration(
                        color: isPlayed
                            ? const Color(0xFFFF4081)
                            : Colors.white.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? _formatDuration(_position)
                      : (_duration != Duration.zero
                          ? _formatDuration(_duration)
                          : 'Ovozli xabar'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

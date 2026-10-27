import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final double sizeMb;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sizeMb,
  });
}

class UpdaterService {
  // Current installed app version
  static const String currentVersion = '1.0.9';
  static const MethodChannel _channel = MethodChannel('com.serenelle.direct/updater');

  /// Check GitHub Releases for newer version
  static Future<UpdateInfo?> checkUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final request = await client.getUrl(
        Uri.parse('https://api.github.com/repos/akbaraliyv/serenelle-mobile/releases/latest'),
      );
      request.headers.set('User-Agent', 'SerenelleDirect-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close();
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
      if (tagName.isEmpty) return null;

      // Compare semantic versions (e.g. 1.0.2 vs 1.0.1)
      if (_isNewer(tagName, currentVersion)) {
        final assets = data['assets'] as List<dynamic>? ?? [];
        if (assets.isEmpty) return null;

        // Find .apk asset
        final apkAsset = assets.firstWhere(
          (a) => (a['name'] as String? ?? '').endsWith('.apk'),
          orElse: () => assets.first,
        );

        final downloadUrl = apkAsset['browser_download_url'] as String;
        final sizeBytes = (apkAsset['size'] as num?)?.toInt() ?? 0;
        final sizeMb = sizeBytes > 0 ? sizeBytes / (1024 * 1024) : 27.4;
        final notes = data['body'] as String? ?? 'Yangi yaxshilanishlar va optimallashlar.';

        return UpdateInfo(
          version: data['tag_name'] as String,
          releaseNotes: notes,
          downloadUrl: downloadUrl,
          sizeMb: sizeMb,
        );
      }
    } catch (e) {
      debugPrint('Auto-updater check error: $e');
    }
    return null;
  }

  static bool _isNewer(String latest, String current) {
    try {
      final lParts = latest.split('.').map(int.parse).toList();
      final cParts = current.split('.').map(int.parse).toList();
      for (int i = 0; i < lParts.length && i < cParts.length; i++) {
        if (lParts[i] > cParts[i]) return true;
        if (lParts[i] < cParts[i]) return false;
      }
      return lParts.length > cParts.length;
    } catch (_) {
      return latest != current;
    }
  }

  /// Show sleek modern In-App Update BottomSheet
  static void showUpdatePrompt(BuildContext context, UpdateInfo info) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UpdateBottomSheet(info: info),
    );
  }

  /// Trigger Native Android PackageInstaller Intent via MethodChannel
  static Future<void> installApk(String filePath) async {
    try {
      await _channel.invokeMethod('installApk', {'filePath': filePath});
    } on PlatformException catch (e) {
      debugPrint('Failed to install APK: ${e.message}');
    }
  }
}

class _UpdateBottomSheet extends StatefulWidget {
  final UpdateInfo info;
  const _UpdateBottomSheet({required this.info});

  @override
  State<_UpdateBottomSheet> createState() => _UpdateBottomSheetState();
}

class _UpdateBottomSheetState extends State<_UpdateBottomSheet> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _statusText = 'Yangilash mavjud';
  String? _error;

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusText = 'Yuklanmoqda... 0%';
      _error = null;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/update_${widget.info.version}.apk');
      if (file.existsSync()) file.deleteSync();

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(widget.info.downloadUrl));
      request.headers.set('User-Agent', 'SerenelleDirect-App');
      final response = await request.close();

      if (response.statusCode != 200 && response.statusCode != 302) {
        throw Exception("Server javobi: ${response.statusCode}");
      }

      final contentLength = response.contentLength;
      int received = 0;
      final sink = file.openWrite();

      await response.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0 && mounted) {
          setState(() {
            _progress = received / contentLength;
            _statusText = 'Yuklanmoqda... ${(_progress * 100).toInt()}%';
          });
        }
      });

      await sink.flush();
      await sink.close();

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusText = 'Yuklab olindi! O\'rnatilmoqda...';
        });
      }

      // Automatically trigger Android PackageInstaller
      await UpdaterService.installApk(file.path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = 'Xatolik: $e';
          _statusText = 'Qayta urinish';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF160F1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x33FF2A6D), width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF2A6D), Color(0xFF9C27B0)],
                  ),
                ),
                child: const Icon(Icons.system_update_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yangi versiya mavjud!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Serenelle Direct ${widget.info.version} • ${widget.info.sizeMb.toStringAsFixed(1)} MB',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Release Notes Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              widget.info.releaseNotes,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Progress Bar (if downloading)
          if (_isDownloading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF2A6D)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _statusText,
                style: const TextStyle(
                  color: Color(0xFFFF80AB),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
              ),
            ),

          const SizedBox(height: 16),

          // Action Buttons
          if (!_isDownloading)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: BorderSide(color: Colors.white.withOpacity(0.18)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Keyinroq'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2A6D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shadowColor: const Color(0x66FF2A6D),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Bir zumda yangilash',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

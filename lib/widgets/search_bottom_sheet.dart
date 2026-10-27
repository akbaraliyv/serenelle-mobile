import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chat_message.dart';
import '../services/database_service.dart';

class SearchBottomSheet extends StatefulWidget {
  final Function(int globalIndex, int id) onSelectResult;

  const SearchBottomSheet({
    super.key,
    required this.onSelectResult,
  });

  @override
  State<SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<SearchBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  List<SearchResultItem> _results = [];
  bool _isSearching = false;

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await DatabaseService.instance.searchFts(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF140E1B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4.5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              cursorColor: const Color(0xFFFF2A6D),
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF22172C),
                hintText: "14,170 ta xabardan qidirish...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF4081)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white54),
                        onPressed: () {
                          _controller.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFFF4081), width: 1.5),
                ),
              ),
            ),
          ),

          // Results count indicator
          if (_controller.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    _isSearching
                        ? 'Qidirilmoqda...'
                        : '${_results.length} ta natija topildi',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Search Results List
          Expanded(
            child: _results.isEmpty && _controller.text.isNotEmpty && !_isSearching
                ? Center(
                    child: Text(
                      'Hech narsa topilmadi',
                      style: TextStyle(color: Colors.white.withOpacity(0.4)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.06),
                      height: 1,
                    ),
                    itemBuilder: (context, i) {
                      final item = _results[i];
                      final isMe = item.senderName == 'Azizbek';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        tileColor: Colors.transparent,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          widget.onSelectResult(item.globalIndex, item.id);
                        },
                        title: Row(
                          children: [
                            Text(
                              item.senderName,
                              style: TextStyle(
                                color: isMe ? const Color(0xFFFF80AB) : const Color(0xFFBA68C8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.dateFormatted,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            item.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF1EBF5),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

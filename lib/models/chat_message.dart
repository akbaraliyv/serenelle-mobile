class ChatMessage {
  final int id;
  final String sender; // 'me' or 'them'
  final String senderName;
  final String? text;
  final String dateFormatted;
  final String timeStr;
  final String isoDate;
  final String? imageName;
  final String? audioName;
  final String? videoName;
  final String? reaction;
  final bool isCall;
  final int? replyId;
  final String? replyText;
  final String? replySender;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.senderName,
    this.text,
    required this.dateFormatted,
    required this.timeStr,
    required this.isoDate,
    this.imageName,
    this.audioName,
    this.videoName,
    this.reaction,
    this.isCall = false,
    this.replyId,
    this.replyText,
    this.replySender,
  });

  bool get isMe => sender == 'me';

  bool get isStickerEmoji {
    if (text == null) return false;
    final trimmed = text!.trim();
    if (trimmed.isEmpty) return false;
    // Check if message consists purely of 1-3 emojis with no letters or digits
    final emojiRegex = RegExp(r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff]|❤️|👍|🗿|😂|🔥|✨|🥰|😭|🥺|👏|❌|✅)+$');
    return emojiRegex.hasMatch(trimmed) && trimmed.length <= 12;
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int,
      sender: map['sender'] as String,
      senderName: map['sender_name'] as String,
      text: map['text'] as String?,
      dateFormatted: map['date_formatted'] as String,
      timeStr: map['time_str'] as String,
      isoDate: map['iso_date'] as String,
      imageName: map['image_name'] as String?,
      audioName: map['audio_name'] as String?,
      videoName: map['video_name'] as String?,
      reaction: map['reaction'] as String?,
      isCall: (map['is_call'] as int?) == 1,
      replyId: map['reply_id'] as int?,
      replyText: map['reply_text'] as String?,
      replySender: map['reply_sender'] as String?,
    );
  }
}

class DateMeta {
  final String isoDate;
  final String dateFormatted;
  final int count;
  final int firstIndex;
  final int firstId;

  DateMeta({
    required this.isoDate,
    required this.dateFormatted,
    required this.count,
    required this.firstIndex,
    required this.firstId,
  });

  factory DateMeta.fromMap(Map<String, dynamic> map) {
    return DateMeta(
      isoDate: map['iso_date'] as String,
      dateFormatted: map['date_formatted'] as String,
      count: map['count'] as int,
      firstIndex: map['first_index'] as int,
      firstId: map['first_id'] as int,
    );
  }
}

class SearchResultItem {
  final int id;
  final String text;
  final String senderName;
  final String dateFormatted;
  final int globalIndex;

  SearchResultItem({
    required this.id,
    required this.text,
    required this.senderName,
    required this.dateFormatted,
    required this.globalIndex,
  });
}

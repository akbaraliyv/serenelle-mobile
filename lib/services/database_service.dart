import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'serenelle_chat_v2.db');

    // Check if database already exists in app storage
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy pre-compiled SQLite database with all 14,170 messages & FTS5 from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      final data = await rootBundle.load('assets/database/chat.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(
      path,
      readOnly: true,
      singleInstance: true,
    );
  }

  /// Load all 14,170 messages into high-speed memory array for 0.00ms latency
  Future<List<ChatMessage>> getAllMessages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      orderBy: 'id ASC',
    );
    return maps.map((m) => ChatMessage.fromMap(m)).toList(growable: false);
  }

  /// Blazing-fast SQLite FTS5 Full-Text Search with instant prefix matching
  Future<List<SearchResultItem>> searchFts(String query) async {
    if (query.trim().isEmpty) return [];

    final db = await database;
    final sanitized = query.replaceAll(RegExp(r'["\x27*]'), '').trim();
    if (sanitized.isEmpty) return [];

    // FTS5 MATCH query with wildcard prefix
    final matchExpression = '$sanitized*';

    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT id, text, sender_name, date_formatted
      FROM messages_fts
      WHERE messages_fts MATCH ?
      ORDER BY rank
      LIMIT 100
    ''', [matchExpression]);

    return results.map((row) {
      final id = row['id'] as int;
      return SearchResultItem(
        id: id,
        text: row['text'] as String,
        senderName: row['sender_name'] as String,
        dateFormatted: row['date_formatted'] as String,
        globalIndex: id - 1, // ID is 1-indexed, index is 0-indexed
      );
    }).toList();
  }

  /// Get 95 unique calendar dates with counts and jump indices
  Future<List<DateMeta>> getDates() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'dates_meta',
      orderBy: 'iso_date ASC',
    );
    return maps.map((m) => DateMeta.fromMap(m)).toList();
  }

  /// Get stats metadata
  Future<Map<String, String>> getStats() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('stats_meta');
    final Map<String, String> map = {};
    for (final row in maps) {
      map[row['key'] as String] = row['value'] as String;
    }
    return map;
  }
}

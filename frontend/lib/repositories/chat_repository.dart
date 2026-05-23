import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  static const String systemUserId = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2";

  /// Stream both sent and received messages in a single efficient channel.
  Stream<List<ChatMessage>> messageStream(String currentUserId, String otherUserId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .map((data) {
          final messages = data
              .map((json) => ChatMessage.fromJson(json))
              .where((msg) =>
                  (msg.senderId == currentUserId && msg.receiverId == otherUserId) ||
                  (msg.senderId == otherUserId && msg.receiverId == currentUserId))
              .toList();
          
          // Sort chronologically
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return messages;
        });
  }
  Future<void> sendSystemMessage(String receiverId, String content) async {
    // Before sending, check if we need to cleanup based on the stacking rule (max 5)
    await _cleanupSystemMessages(receiverId);

    await _client.from('messages').insert({
      'sender_id': systemUserId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
    });
  }

  Future<void> _cleanupSystemMessages(String receiverId) async {
    try {
      // Fetch system messages for this user
      final response = await _client
          .from('messages')
          .select('id')
          .eq('sender_id', systemUserId)
          .eq('receiver_id', receiverId)
          .order('created_at', ascending: false);
      
      final messages = response as List;
      if (messages.length >= 5) {
        // Delete all existing system messages for this user since the 6th one is about to be sent
        final idsToDelete = messages.map((m) => m['id']).toList();
        await _client.from('messages').delete().inFilter('id', idsToDelete);
      }
    } catch (e) {
      print("System message cleanup error: $e");
    }
  }


  Future<void> sendMessage(String senderId, String receiverId, String content) async {
    await _client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'content': content,
      'is_read': false,
    });
  }

  Future<void> markAsRead(String messageId) async {
    await _client.from('messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }
}

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../services/websocket_service.dart';

class ChatRepository {
  final SupabaseClient _client;
  WebSocketService? _wsService;
  StreamSubscription? _wsSubscription;
  final _messageStreamController = StreamController<ChatMessage>.broadcast();
  DateTime? _lastMessageReceivedAt;

  ChatRepository(this._client) {
    _initWebSocket();
  }

  static const String systemUserId = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2";

  void _initWebSocket() {
    final session = _client.auth.currentSession;
    if (session == null) return;

    _wsService = WebSocketService(session.accessToken);
    
    // Listen to WS connection state for auto-syncing after reconnect
    _wsService!.connectionState.listen((state) {
      if (state == WebSocketConnectionState.connected && _lastMessageReceivedAt != null) {
        _syncMissedMessages();
      }
    });

    _wsSubscription = _wsService!.messages.listen((data) {
      if (data['type'] == 'msg' || data['type'] == 'ack') {
        final payload = data['payload'];
        // Backend doesn't return created_at immediately in broadcast to save DB roundtrip, 
        // so we use local time if missing, though Supabase will assign the definitive one.
        final msg = ChatMessage(
          id: payload['id'] ?? 'ws-${DateTime.now().millisecondsSinceEpoch}',
          senderId: payload['sender_id'],
          receiverId: payload['receiver_id'],
          content: payload['content'],
          createdAt: payload['created_at'] != null 
              ? DateTime.parse(payload['created_at']) 
              : DateTime.now().toUtc(),
          isRead: false,
        );
        _lastMessageReceivedAt = msg.createdAt;
        _messageStreamController.add(msg);
      }
    });
  }

  /// Initial load of message history
  Future<List<ChatMessage>> getMessageHistory(String currentUserId, String otherUserId) async {
    final response = await _client
        .from('messages')
        .select()
        .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)')
        .order('created_at', ascending: true);
    
    final messages = (response as List).map((json) => ChatMessage.fromJson(json)).toList();
    if (messages.isNotEmpty) {
      _lastMessageReceivedAt = messages.last.createdAt;
    }
    return messages;
  }

  /// Differential fetch for offline gaps
  Future<void> _syncMissedMessages() async {
    if (_lastMessageReceivedAt == null) return;
    
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final response = await _client
          .from('messages')
          .select()
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .gt('created_at', _lastMessageReceivedAt!.toIso8601String())
          .order('created_at', ascending: true);
      
      final messages = (response as List).map((json) => ChatMessage.fromJson(json)).toList();
      for (var msg in messages) {
        _messageStreamController.add(msg);
        _lastMessageReceivedAt = msg.createdAt;
      }
    } catch (e) {
      print("Error syncing missed messages: $e");
    }
  }

  /// Stream of real-time messages (WS + Syncs)
  Stream<ChatMessage> get realTimeMessages => _messageStreamController.stream;

  Future<void> sendSystemMessage(String receiverId, String content) async {
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
      final response = await _client
          .from('messages')
          .select('id')
          .eq('sender_id', systemUserId)
          .eq('receiver_id', receiverId)
          .order('created_at', ascending: false);
      
      final messages = response as List;
      if (messages.length >= 5) {
        final idsToDelete = messages.map((m) => m['id']).toList();
        await _client.from('messages').delete().inFilter('id', idsToDelete);
      }
    } catch (e) {
      print("System message cleanup error: $e");
    }
  }

  Future<void> sendMessage(String senderId, String receiverId, String content) async {
    if (_wsService?.currentState == WebSocketConnectionState.connected) {
      _wsService!.sendMessage(receiverId, content);
    } else {
      // Fallback to REST if WS is down
      await _client.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'is_read': false,
      });
    }
  }

  Future<void> markAsRead(String messageId) async {
    await _client.from('messages').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId);
  }

  void dispose() {
    _wsSubscription?.cancel();
    _wsService?.dispose();
    _messageStreamController.close();
  }
}

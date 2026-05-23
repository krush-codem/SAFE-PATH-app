import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../providers/repository_providers.dart';

import '../providers/auth_provider.dart';

/// Holds messages that were just sent but haven't reached the database yet.
/// We use a generic Provider mapped with another Map to avoid Riverpod's complex family class typing issues
class OptimisticMessagesNotifier extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() {
    return {};
  }

  void addMessage(String receiverId, ChatMessage message) {
    final currentList = state[receiverId] ?? [];
    state = {
      ...state,
      receiverId: [...currentList, message]
    };
  }

  void removeMessage(String receiverId, String messageId) {
    final currentList = state[receiverId] ?? [];
    state = {
      ...state,
      receiverId: currentList.where((m) => m.id != messageId).toList()
    };
  }
  
  List<ChatMessage> getMessages(String receiverId) {
    return state[receiverId] ?? [];
  }
}

final optimisticMessagesProvider = NotifierProvider<OptimisticMessagesNotifier, Map<String, List<ChatMessage>>>(() {
  return OptimisticMessagesNotifier();
});

/// Combines database messages with optimistic local messages for instant UI.
final allMessagesProvider = Provider.family<AsyncValue<List<ChatMessage>>, String>((ref, otherUserId) {
  // Watch a ticker to force this provider to re-evaluate its filter every 10 seconds.
  // This ensures that expired messages (5m/30m) are removed from the list automatically.
  ref.watch(chatRefreshTickerProvider);
  
  final currentUser = ref.watch(currentUserProvider);
  final currentUserId = currentUser?.id ?? '';
  final dbMessagesAsync = ref.watch(chatMessagesProvider(otherUserId));
  final optimisticDict = ref.watch(optimisticMessagesProvider);
  final optimisticMessages = optimisticDict[otherUserId] ?? [];

  return dbMessagesAsync.whenData((dbMsgsRaw) {
    final dbMsgs = dbMsgsRaw.where((msg) {
      final now = DateTime.now().toUtc();
      final isMe = msg.senderId == currentUserId;
      final isSos = msg.content.toUpperCase().contains('SOS ALERT');

      // System messages don't expire from the list by time
      if (msg.senderId == 'system') return true;

      final startTime = (isMe || msg.readAt == null) ? msg.createdAt : msg.readAt!;
      final diff = now.difference(startTime).inMinutes;
      final limit = isSos ? 6.0 : 5.0; // Show SOS for 6 mins, regular for 5 mins

      return diff < limit;
    }).toList();

    // Filter out optimistic messages that are now in the DB (deduplication)
    final filteredOptimistic = optimisticMessages.where((om) => 
      !dbMsgs.any((dm) => dm.content == om.content && dm.senderId == om.senderId)
    ).toList();
    
    return [...dbMsgs, ...filteredOptimistic];
  });
});

/// A simple ticker that increments every 10 seconds to force provider refreshes.
final chatRefreshTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (i) => i);
});

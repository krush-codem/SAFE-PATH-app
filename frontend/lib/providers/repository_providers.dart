import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/chat_repository.dart';
import '../repositories/place_repository.dart';
import '../repositories/directions_repository.dart';
import '../repositories/journey_repository.dart';
import '../providers/auth_provider.dart';

import '../core/config/env_config.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(supabaseClientProvider));
});

final directionsRepositoryProvider = Provider<DirectionsRepository>((ref) {
  return DirectionsRepository(
    dio: ref.watch(dioProvider),
    apiKey: EnvConfig.googleMapsApiKey,
  );
});

final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  return PlaceRepository(EnvConfig.googleMapsApiKey);
});

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(ref.watch(supabaseClientProvider));
});

final chatMessagesProvider = StreamProvider.family<List<dynamic>, String>((ref, otherUserId) async* {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  if (currentUserId == null) {
    yield [];
    return;
  }

  final repo = ref.watch(chatRepositoryProvider);
  
  // 1. Initial Load
  List<dynamic> currentMessages = await repo.getMessageHistory(currentUserId, otherUserId);
  yield currentMessages;

  // 2. Listen to Real-time Stream
  await for (final newMessage in repo.realTimeMessages) {
    // Only yield if the message belongs to this conversation
    if ((newMessage.senderId == currentUserId && newMessage.receiverId == otherUserId) ||
        (newMessage.senderId == otherUserId && newMessage.receiverId == currentUserId)) {
      
      // Prevent duplicates from optimistic UI or double-sync
      if (!currentMessages.any((m) => m.id == newMessage.id)) {
        currentMessages = [...currentMessages, newMessage];
        currentMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        yield currentMessages;
      }
    }
  }
});

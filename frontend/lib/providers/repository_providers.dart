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

final chatMessagesProvider = StreamProvider.family<List<dynamic>, String>((ref, otherUserId) {
  final currentUserId = ref.watch(currentUserProvider)?.id;
  if (currentUserId == null) return Stream.value([]);
  return ref.watch(chatRepositoryProvider).messageStream(currentUserId, otherUserId);
});

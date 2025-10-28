import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/services/auth_service.dart';
import '../../features/location/services/location_service.dart';
import '../../features/location/services/cell_tracking_service.dart';
import '../../features/post/services/post_service.dart';

part 'app_providers.g.dart';

// Auth Service Provider
@Riverpod(keepAlive: true)
Future<void> authServiceInit(AuthServiceInitRef ref) async {
  final authService = AuthService();
  await authService.loadStoredTokens();
  ref.onDispose(() {
    // Clean up if needed
  });
}

@Riverpod(keepAlive: true)
AuthService authService(AuthServiceRef ref) {
  return AuthService();
}

// Location Service Provider  
@Riverpod(keepAlive: true)
LocationService locationService(LocationServiceRef ref) {
  return LocationService();
}

// Post Service Provider
@Riverpod(keepAlive: true)
PostService postService(PostServiceRef ref) {
  final authService = ref.watch(authServiceProvider);
  return PostService(authService: authService);
}

// Cell Tracking Service Provider
@Riverpod(keepAlive: true)
CellTrackingService cellTrackingService(CellTrackingServiceRef ref) {
  final authService = ref.watch(authServiceProvider);
  return CellTrackingService(authService: authService);
}


// SharedPreferences Provider
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return await SharedPreferences.getInstance();
}
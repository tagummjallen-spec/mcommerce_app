import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Firebase auth stream (null when guest)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Local guest flag: true when the user explicitly entered as guest
final guestModeProvider = StateProvider<bool>((ref) => false);

// Current user profile loaded from Firestore
final currentUserProfileProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.watch(authStateProvider);
  final user = auth.valueOrNull;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getUserProfile(user.uid);
});

// Convenience: whether the app is in guest (not logged in) mode
final isGuestProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user == null;
});

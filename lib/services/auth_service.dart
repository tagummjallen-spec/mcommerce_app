import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream auth user
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Register user
  Future<UserModel> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
    String phone = '',
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception("Registration failed. Please try again.");
      }

      // Update display name
      await user.updateDisplayName(fullName);

      // Create UserModel
      final userModel = UserModel(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        role: 'customer',
        createdAt: DateTime.now(),
      );

      // Store in Firestore users/{uid}
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Login user
  Future<UserModel> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        throw Exception("Login failed. User not found.");
      }

      // Fetch Firestore user doc
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, user.uid);
      } else {
        // Fallback user model if doc missing
        final fallbackModel = UserModel(
          uid: user.uid,
          fullName: user.displayName ?? 'Customer',
          email: user.email ?? email,
        );
        await _firestore.collection('users').doc(user.uid).set(fallbackModel.toMap());
        return fallbackModel;
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Get User Profile Doc
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    }
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    if (_auth.currentUser != null) {
      await _auth.currentUser!.updatePassword(newPassword);
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account exists with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'Authentication failed ($code). Please check your credentials.';
    }
  }
}

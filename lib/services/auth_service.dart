import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth state changes (User? or null)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current logged-in user
  User? get currentUser => _auth.currentUser;

  // Designated admin email
  static const String adminEmail = 'darrennenel@gmail.com';

  // Check if current user is Admin
  bool get isAdmin => isAdminUser(currentUser);

  // Check if given user is Admin
  static bool isAdminUser(User? user) {
    if (user == null || user.isAnonymous) return false;
    final email = user.email?.trim().toLowerCase();
    return email == adminEmail.toLowerCase();
  }

  // Sign in with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Register with Email, Password and Display Name
  Future<UserCredential> createUserWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
      }
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the interactive authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User aborted/canceled the sign-in modal
        return null;
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Guest / Anonymous Sign-In
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore if not logged in via Google
    }
    await _auth.signOut();
  }

  // Friendly error message helper
  static String getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for this email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      case 'weak-password':
        return 'The password is too weak. Must be at least 6 characters.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few moments.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is disabled in your Firebase Console. Please enable it under Authentication > Sign-in method.';
      case 'channel-error':
        if (e.message != null && e.message!.contains('operation-not-allowed')) {
          return 'Email/Password sign-in is disabled in your Firebase Console. Please enable it under Authentication > Sign-in method.';
        }
        return 'Firebase Authentication service error. Please make sure Email/Password is enabled in the Firebase Console.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        final msg = e.message;
        if (msg != null &&
            msg.isNotEmpty &&
            !msg.startsWith('dev.flutter.pigeon')) {
          return msg;
        }
        return 'Authentication failed (${e.code}). Please ensure Email/Password provider is enabled in Firebase Console.';
    }
  }
}

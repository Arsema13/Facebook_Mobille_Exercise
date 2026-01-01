import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Stream<User?> get userStream => _auth.authStateChanges();

  // 1. Updated Sign Up to include Name
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set the user's display name immediately after account creation
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.reload(); // Refresh user data
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print("Sign Up Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // 2. Standard Email Login
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print("Login Error: ${e.code} - ${e.message}");
      rethrow;
    }
  }

  // 3. Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // 4. Complete Sign Out
  Future<void> signOut() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      await _auth.signOut();
      print("Logged out successfully.");
    } catch (e) {
      await _auth.signOut();
      print("Sign Out Error: $e");
    }
  }

  // Getters
  String? get currentUserUid => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;
}
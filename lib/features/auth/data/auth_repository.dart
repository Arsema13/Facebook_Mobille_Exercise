import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/firebase/auth_service.dart';
import '../../../services/firebase/firestore_service.dart'; // Ensure you have this

class AuthRepository {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // 1. Login with Email/Password
  Future<User?> login(String email, String password) async {
    final userCredential = await _authService.signInWithEmail(email, password);
    return userCredential?.user;
  }

  // 2. Updated Register: Now takes Name and Phone
  Future<User?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create the Auth Account and set Display Name
      final userCredential = await _authService.signUp(
        email: email,
        password: password,
        name: name,
      );

      final user = userCredential?.user;

      if (user != null) {
        // Save extra data (Name, Phone, Email) to Firestore 'users' collection
        await _firestoreService.saveUserData(
          uid: user.uid,
          name: name,
          email: email,
          phone: phone,
        );
      }
      return user;
    } catch (e) {
      print("Repository Registration Error: $e");
      rethrow;
    }
  }

  // 3. Google Login with Auto-Profile Save
  Future<User?> loginWithGoogle() async {
    try {
      final userCredential = await _authService.signInWithGoogle();
      final user = userCredential?.user;

      if (user != null) {
        // Ensure Google users also have a document in our 'users' collection
        await _firestoreService.saveUserData(
          uid: user.uid,
          name: user.displayName ?? "Google User",
          email: user.email ?? "",
          phone: user.phoneNumber ?? "",
          profilePic: user.photoURL,
        );
      }
      return user;
    } catch (e) {
      print("Repository Google Error: $e");
      return null;
    }
  }
}
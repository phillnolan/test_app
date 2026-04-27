import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static Future<void>? _googleSignInInitialization;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _auth => isAvailable ? FirebaseAuth.instance : null;

  /// Initializes the shared Google Sign-In instance once.
  Future<void> initializeGoogleSignIn() async {
    if (!isAvailable) {
      return;
    }

    final existingInitialization = _googleSignInInitialization;
    if (existingInitialization != null) {
      await existingInitialization;
      return;
    }

    final initialization = GoogleSignIn.instance.initialize();
    _googleSignInInitialization = initialization;

    try {
      await initialization;
    } catch (_) {
      _googleSignInInitialization = null;
      rethrow;
    }
  }

  Stream<User?> authStateChanges() {
    if (!isAvailable) return const Stream<User?>.empty();
    return _auth!.authStateChanges();
  }

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureReady();
    return _auth!.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    _ensureReady();
    return _auth!.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    _ensureReady();
    await initializeGoogleSignIn();
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-google-id-token',
        message: 'Khong the lay ma xac thuc tu Google.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth!.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
    await initializeGoogleSignIn();
    await GoogleSignIn.instance.signOut();
    await _auth!.signOut();
  }

  void _ensureReady() {
    if (!isAvailable) {
      throw FirebaseAuthException(
        code: 'firebase-not-initialized',
        message: 'Firebase chưa được khởi tạo.',
      );
    }
  }
}

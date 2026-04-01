import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseAuth? get _auth => isAvailable ? FirebaseAuth.instance : null;

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
    final googleUser = await GoogleSignIn.instance.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    return _auth!.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!isAvailable) return;
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

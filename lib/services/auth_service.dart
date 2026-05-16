import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ดึง User ปัจจุบัน
  User? get currentUser => _auth.currentUser;

  // Stream สำหรับเช็ค Auth State
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // สมัครสมาชิกด้วย Email/Password
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // เข้าสู่ระบบด้วย Email/Password
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // เข้าสู่ระบบด้วย Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // เปิดหน้าต่าง Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // ถ้าผู้ใช้ปิดหน้าต่างก่อน
      if (googleUser == null) return null;

      // ดึง Auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in เข้า Firebase
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'เกิดข้อผิดพลาดกับ Google Sign-In กรุณาลองใหม่อีกครั้ง';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ออกจากระบบ
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // แปลง Firebase Error เป็นข้อความภาษาไทย
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email นี้ถูกใช้งานแล้ว';
      case 'invalid-email':
        return 'รูปแบบ Email ไม่ถูกต้อง';
      case 'weak-password':
        return 'Password ต้องมีอย่างน้อย 6 ตัวอักษร';
      case 'user-not-found':
        return 'ไม่พบ Email นี้ในระบบ';
      case 'wrong-password':
        return 'Password ไม่ถูกต้อง';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
    }
  }
}

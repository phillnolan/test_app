import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/home_action_result.dart';
import '../services/auth_service.dart';
import 'home_flow_models.dart';

class AccountAuthController {
  AccountAuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool get isAvailable => _authService.isAvailable;

  User? get currentUser => _authService.currentUser;

  StreamSubscription<User?> listenAuthState(ValueChanged<User?> onChanged) {
    return _authService.authStateChanges().listen(onChanged);
  }

  Future<HomeActionResult> submitEmailAuth(EmailAuthResult result) async {
    final messages = switch (result.mode) {
      EmailAuthMode.signIn => (
        success: 'Đăng nhập tài khoản thành công.',
        failure: 'Không thể đăng nhập.',
      ),
      EmailAuthMode.register => (
        success: 'Đăng ký tài khoản thành công.',
        failure: 'Không thể đăng ký.',
      ),
    };

    try {
      if (result.mode == EmailAuthMode.signIn) {
        await _authService.signInWithEmail(
          email: result.email,
          password: result.password,
        );
      } else {
        await _authService.registerWithEmail(
          email: result.email,
          password: result.password,
        );
      }

      return HomeActionResult.success(messages.success);
    } on FirebaseAuthException catch (error) {
      return HomeActionResult.failure(error.message ?? messages.failure);
    } catch (_) {
      return HomeActionResult.failure(messages.failure);
    }
  }

  Future<HomeActionResult> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      return const HomeActionResult.success('Đã đăng nhập Google.');
    } on FirebaseAuthException catch (error) {
      return HomeActionResult.failure(
        error.message ?? 'Không thể đăng nhập Google.',
      );
    } catch (_) {
      return const HomeActionResult.failure('Không thể đăng nhập Google.');
    }
  }

  Future<HomeActionResult> signOut() async {
    await _authService.signOut();
    return const HomeActionResult.success('Đã đăng xuất.');
  }
}

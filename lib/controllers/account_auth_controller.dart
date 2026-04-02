import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../views/home/widgets/home_dialogs.dart';
import '../views/home/widgets/home_sheet_models.dart';

class AccountAuthController {
  AccountAuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool get isAvailable => _authService.isAvailable;

  User? get currentUser => _authService.currentUser;

  StreamSubscription<User?> listenAuthState(ValueChanged<User?> onChanged) {
    return _authService.authStateChanges().listen(onChanged);
  }

  Future<void> openEmailAuthSheet(BuildContext context) async {
    final result = await showModalBottomSheet<EmailAuthResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const EmailAuthSheet(),
    );
    if (result == null || !context.mounted) {
      return;
    }

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

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng nhập tài khoản thành công.')),
      );
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Không thể đăng nhập.')),
      );
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      await _authService.signInWithGoogle();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã đăng nhập Google.')));
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Không thể đăng nhập Google.')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng nhập Google.')),
      );
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _authService.signOut();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã đăng xuất.')));
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/home_action_result.dart';
import '../../../services/teldrive_api_client.dart';
import '../../../services/teldrive_models.dart';
import '../../home/domain/home_flow_models.dart';
import '../data/auth_service.dart';

/// Provides the shared [AccountAuthController] for Teldrive connection flows.
final accountAuthControllerProvider = Provider<AccountAuthController>(
  (ref) => AccountAuthController(),
);

final class AccountAuthController {
  AccountAuthController({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  bool get isAvailable => _authService.isAvailable;

  TeldriveSessionInfo? get currentUser => _authService.currentUser;

  StreamSubscription<TeldriveSessionInfo?> listenAuthState(
    ValueChanged<TeldriveSessionInfo?> onChanged,
  ) {
    return _authService.authStateChanges().listen(onChanged);
  }

  Future<HomeActionResult> submitEmailAuth(EmailAuthResult result) async {
    final messages = switch (result.mode) {
      EmailAuthMode.signIn => (
        success: 'Đã liên kết Teledrive thành công.',
        failure: 'Không thể liên kết Teledrive.',
      ),
      EmailAuthMode.register => (
        success: 'Đã lưu cấu hình Teledrive thành công.',
        failure: 'Không thể lưu cấu hình Teledrive.',
      ),
    };

    try {
      await _authService.signInWithEmail(
        email: result.email,
        password: result.password,
      );
      return HomeActionResult.success(messages.success);
    } on TeldriveApiException catch (error) {
      return HomeActionResult.failure(error.message);
    } catch (_) {
      return HomeActionResult.failure(messages.failure);
    }
  }

  Future<HomeActionResult> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
      return const HomeActionResult.success('Đã làm mới kết nối Teledrive.');
    } on TeldriveApiException catch (error) {
      return HomeActionResult.failure(error.message);
    } catch (_) {
      return const HomeActionResult.failure('Không thể làm mới Teledrive.');
    }
  }

  Future<HomeActionResult> signOut() async {
    await _authService.signOut();
    return const HomeActionResult.success('Đã ngắt kết nối Teledrive.');
  }
}

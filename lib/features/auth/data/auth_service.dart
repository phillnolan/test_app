import 'dart:async';

import '../../../services/teldrive_api_client.dart';
import '../../../services/teldrive_models.dart';

class AuthService {
  AuthService({TeldriveApiClient? client})
    : _client = client ?? TeldriveApiClient();

  final TeldriveApiClient _client;
  static final StreamController<TeldriveSessionInfo?> _sessionController =
      StreamController<TeldriveSessionInfo?>.broadcast();

  static TeldriveConnectionConfig? _cachedConfig;
  static TeldriveSessionInfo? _currentSession;

  bool get isAvailable => _cachedConfig != null;

  TeldriveSessionInfo? get currentUser => _currentSession;

  Future<void> initializeConnection() async {
    _cachedConfig = await _client.loadConfig();
    if (_cachedConfig == null) {
      _updateSession(null);
      return;
    }

    await _refreshSession();
  }

  Future<void> connect({
    required String baseUrl,
    required String accessToken,
  }) async {
    final session = await _client.connect(
      baseUrl: baseUrl,
      accessToken: accessToken,
    );
    _cachedConfig = await _client.loadConfig();
    _updateSession(session);
  }

  Stream<TeldriveSessionInfo?> authStateChanges() {
    return _sessionController.stream;
  }

  Future<TeldriveSessionInfo?> refreshSession() async {
    return _refreshSession();
  }

  Future<void> signOut() async {
    await _client.disconnect();
    _cachedConfig = null;
    _updateSession(null);
  }

  Future<TeldriveSessionInfo> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await connect(baseUrl: email, accessToken: password);
    final session = _currentSession;
    if (session == null) {
      throw TeldriveApiException(
        'Không thể xác thực với Teledrive. Hãy thử lại.',
      );
    }
    return session;
  }

  Future<TeldriveSessionInfo> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return signInWithEmail(email: email, password: password);
  }

  Future<TeldriveSessionInfo?> signInWithGoogle() async {
    return refreshSession();
  }

  void _updateSession(TeldriveSessionInfo? session) {
    _currentSession = session;
    if (!_sessionController.isClosed) {
      _sessionController.add(session);
    }
  }

  Future<TeldriveSessionInfo?> _refreshSession() async {
    final session = await _client.fetchSession();
    if (session == null) {
      _updateSession(null);
      return null;
    }

    _updateSession(session);
    return session;
  }
}

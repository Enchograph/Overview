import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.email,
    required this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return AuthSession(
      token: json['token'] as String,
      userId: user['id'] as String,
      email: user['email'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String token;
  final String userId;
  final String email;
  final DateTime expiresAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'user': {
        'id': userId,
        'email': email,
      },
    };
  }
}

abstract class AuthRepository {
  Future<AuthSession?> fetchSession();
  Future<AuthSession> register({
    required String email,
    required String password,
  });
  Future<AuthSession> login({
    required String email,
    required String password,
  });
  Future<void> logout();
  bool get isRemoteEnabled;
}

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class HttpAuthRepository {
  HttpAuthRepository({
    required String baseUrl,
    HttpClient? httpClient,
  })  : _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final payload = await _request(
      '/auth/register',
      {
        'email': email,
        'password': password,
      },
    );
    return AuthSession.fromJson(payload);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final payload = await _request(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
    );
    return AuthSession.fromJson(payload);
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final request = await _httpClient.postUrl(_baseUri.resolve(path));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthRepositoryException(
        body.isEmpty ? 'Request failed with ${response.statusCode}' : body,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const AuthRepositoryException('Unexpected response payload');
  }
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    SharedPreferencesLoader? preferencesLoader,
    HttpAuthRepository? remoteRepository,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _remoteRepository = remoteRepository;

  static const _storageKey = 'overview.auth.session.v1';

  final SharedPreferencesLoader _preferencesLoader;
  final HttpAuthRepository? _remoteRepository;

  @override
  bool get isRemoteEnabled => _remoteRepository != null;

  @override
  Future<AuthSession?> fetchSession() async {
    final preferences = await _preferencesLoader();
    final rawValue = preferences.getString(_storageKey);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawValue);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final session = AuthSession.fromJson(decoded);
    if (session.isExpired) {
      await logout();
      return null;
    }
    return session;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final remote = _requireRemote();
    final session = await remote.register(email: email, password: password);
    await _persistSession(session);
    return session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final remote = _requireRemote();
    final session = await remote.login(email: email, password: password);
    await _persistSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_storageKey);
  }

  HttpAuthRepository _requireRemote() {
    final remote = _remoteRepository;
    if (remote == null) {
      throw const AuthRepositoryException('Remote auth is not configured.');
    }
    return remote;
  }

  Future<void> _persistSession(AuthSession session) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(_storageKey, jsonEncode(session.toJson()));
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSession? initialSession,
    this.remoteEnabled = true,
  }) : _session = initialSession;

  AuthSession? _session;
  final bool remoteEnabled;

  @override
  bool get isRemoteEnabled => remoteEnabled;

  @override
  Future<AuthSession?> fetchSession() async => _session;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (!remoteEnabled) {
      throw const AuthRepositoryException('Remote auth is not configured.');
    }
    _session = AuthSession(
      token: 'token-login',
      userId: 'user-1',
      email: email,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
    return _session!;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    if (!remoteEnabled) {
      throw const AuthRepositoryException('Remote auth is not configured.');
    }
    _session = AuthSession(
      token: 'token-register',
      userId: 'user-1',
      email: email,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
    return _session!;
  }

  @override
  Future<void> logout() async {
    _session = null;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persists login session across repository instances', () async {
    final server = await _AuthApiStubServer.start();
    addTearDown(server.close);

    final repository = LocalAuthRepository(
      remoteRepository: HttpAuthRepository(baseUrl: server.baseUrl),
    );

    final session = await repository.login(
      email: 'user@example.com',
      password: 'Password123',
    );
    final anotherRepository = LocalAuthRepository(
      remoteRepository: HttpAuthRepository(baseUrl: server.baseUrl),
    );

    final persistedSession = await anotherRepository.fetchSession();
    expect(persistedSession?.email, session.email);
    expect(persistedSession?.token, session.token);
  });

  test('clears persisted session on logout', () async {
    final server = await _AuthApiStubServer.start();
    addTearDown(server.close);

    final repository = LocalAuthRepository(
      remoteRepository: HttpAuthRepository(baseUrl: server.baseUrl),
    );

    await repository.register(
      email: 'logout@example.com',
      password: 'Password123',
    );
    await repository.logout();

    expect(await repository.fetchSession(), isNull);
  });
}

class _AuthApiStubServer {
  _AuthApiStubServer._(this._server);

  static Future<_AuthApiStubServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final stub = _AuthApiStubServer._(server);
    stub._listen();
    return stub;
  }

  final HttpServer _server;
  int _counter = 0;

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  void _listen() {
    _server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (request.uri.path != '/auth/register' && request.uri.path != '/auth/login') {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }

      _counter += 1;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'token': 'token-$_counter',
          'expiresAt': DateTime.now()
              .toUtc()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'user': {
            'id': 'user-$_counter',
            'email': decoded['email'],
          },
        }),
      );
      await request.response.close();
    });
  }

  Future<void> close() => _server.close(force: true);
}

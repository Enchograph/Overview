import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/ai/ai_repository.dart';
import 'package:overview_client/app/auth/auth_repository.dart';

void main() {
  late _AiApiStubServer server;

  setUp(() async {
    server = await _AiApiStubServer.start();
  });

  tearDown(() async {
    await server.close();
  });

  test('parses text over HTTP with bearer token', () async {
    final repository = HttpAiRepository(
      baseUrl: server.baseUrl,
      authSessionProvider: () async => server.createSession(),
    );

    final suggestion = await repository.ingestText('明晚 8 点做英语作业');

    expect(suggestion.suggestedType, AiSuggestionType.task);
    expect(suggestion.title, '明晚 8 点做英语作业');
    expect(suggestion.requiresConfirmation, contains('dueAt'));
  });

  test('asks question over HTTP with bearer token', () async {
    final repository = HttpAiRepository(
      baseUrl: server.baseUrl,
      authSessionProvider: () async => server.createSession(),
    );

    final answer = await repository.askQuestion('明天应该先做什么？');

    expect(answer.answer, contains('Design review'));
    expect(answer.referencedItemCount, 2);
  });

  test('transcribes audio over HTTP with bearer token', () async {
    final repository = HttpAiRepository(
      baseUrl: server.baseUrl,
      authSessionProvider: () async => server.createSession(),
    );

    final transcript = await repository.transcribeAudio(
      audioBytes: const [1, 2, 3],
      mimeType: 'audio/wav',
      locale: 'zh-CN',
    );

    expect(transcript, '明天上午准备董事会更新');
  });
}

class _AiApiStubServer {
  _AiApiStubServer._(this._server);

  static Future<_AiApiStubServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final stub = _AiApiStubServer._(server);
    stub._listen();
    return stub;
  }

  final HttpServer _server;
  final String expectedToken = 'token-ai-test';

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  AuthSession createSession() {
    return AuthSession(
      token: expectedToken,
      userId: 'user-1',
      email: 'user@example.com',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
  }

  void _listen() {
    _server.listen((request) async {
      if (request.headers.value(HttpHeaders.authorizationHeader) !=
          'Bearer $expectedToken') {
        request.response.statusCode = HttpStatus.unauthorized;
        await _writeJson(request.response, {'error': 'Authorization required'});
        return;
      }

      final body = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      if (request.method == 'POST' && request.uri.path == '/ai/ingest/text') {
        await _writeJson(
          request.response,
          {
            'suggestedType': 'task',
            'title': decoded['text'],
            'confidence': 0.84,
            'requiresConfirmation': ['dueAt'],
            'extracted': {'dueAt': '2026-03-13T12:00:00.000Z'},
          },
        );
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/ai/ask') {
        await _writeJson(
          request.response,
          {
            'answer': 'Start with Design review, then finish the launch memo.',
            'referencedItemCount': 2,
          },
        );
        return;
      }

      if (request.method == 'POST' && request.uri.path == '/ai/transcribe') {
        await _writeJson(
          request.response,
          {
            'text': '明天上午准备董事会更新',
            'locale': decoded['locale'],
          },
        );
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await _writeJson(request.response, {'error': 'Not found'});
    });
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _writeJson(
    HttpResponse response,
    Map<String, dynamic> payload,
  ) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }
}

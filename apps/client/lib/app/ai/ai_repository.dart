import 'dart:convert';
import 'dart:io';

import '../auth/auth_repository.dart';

enum AiSuggestionType { schedule, task, memo }

class AiAnswer {
  const AiAnswer({
    required this.answer,
    required this.referencedItemCount,
  });

  factory AiAnswer.fromJson(Map<String, dynamic> json) {
    return AiAnswer(
      answer: json['answer'] as String? ?? '',
      referencedItemCount: (json['referencedItemCount'] as num?)?.toInt() ?? 0,
    );
  }

  final String answer;
  final int referencedItemCount;
}

class AiSuggestion {
  const AiSuggestion({
    required this.suggestedType,
    required this.title,
    required this.confidence,
    required this.requiresConfirmation,
    required this.extracted,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      suggestedType: parseAiSuggestionType(json['suggestedType'] as String?),
      title: json['title'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      requiresConfirmation:
          (json['requiresConfirmation'] as List<dynamic>? ?? const [])
              .map((item) => item as String)
              .toList(),
      extracted: (json['extracted'] as Map<String, dynamic>?) ?? const {},
    );
  }

  final AiSuggestionType suggestedType;
  final String title;
  final double confidence;
  final List<String> requiresConfirmation;
  final Map<String, dynamic> extracted;
}

AiSuggestionType parseAiSuggestionType(String? value) {
  switch (value) {
    case 'schedule':
      return AiSuggestionType.schedule;
    case 'memo':
      return AiSuggestionType.memo;
    case 'task':
    default:
      return AiSuggestionType.task;
  }
}

abstract class AiRepository {
  bool get isRemoteEnabled;
  Future<AiSuggestion> ingestText(String text);
  Future<AiAnswer> askQuestion(String question);
}

class HttpAiRepository implements AiRepository {
  HttpAiRepository({
    required String baseUrl,
    HttpClient? httpClient,
    Future<AuthSession?> Function()? authSessionProvider,
  })  : _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? HttpClient(),
        _authSessionProvider = authSessionProvider;

  final Uri _baseUri;
  final HttpClient _httpClient;
  final Future<AuthSession?> Function()? _authSessionProvider;

  @override
  bool get isRemoteEnabled => true;

  @override
  Future<AiSuggestion> ingestText(String text) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/ai/ingest/text'));
    request.headers.contentType = ContentType.json;
    await _applyAuthorization(request);
    request.write(jsonEncode({'text': text}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiRepositoryException(
        body.isEmpty ? 'Request failed with ${response.statusCode}' : body,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return AiSuggestion.fromJson(decoded);
    }

    throw const AiRepositoryException('Unexpected response payload');
  }

  @override
  Future<AiAnswer> askQuestion(String question) async {
    final request = await _httpClient.postUrl(_baseUri.resolve('/ai/ask'));
    request.headers.contentType = ContentType.json;
    await _applyAuthorization(request);
    request.write(jsonEncode({'question': question}));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AiRepositoryException(
        body.isEmpty ? 'Request failed with ${response.statusCode}' : body,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return AiAnswer.fromJson(decoded);
    }

    throw const AiRepositoryException('Unexpected response payload');
  }

  Future<void> _applyAuthorization(HttpClientRequest request) async {
    final session = await _authSessionProvider?.call();
    final token = session?.token;
    if (token == null || token.isEmpty) {
      return;
    }

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
}

class FakeAiRepository implements AiRepository {
  FakeAiRepository({
    this.remoteEnabled = true,
    AiSuggestion? suggestion,
    AiAnswer? answer,
  }) : _suggestion =
            suggestion ??
            const AiSuggestion(
              suggestedType: AiSuggestionType.task,
              title: 'Parsed task',
              confidence: 0.82,
              requiresConfirmation: ['dueAt'],
              extracted: {},
            ),
        _answer =
            answer ??
            const AiAnswer(
              answer: 'You have 3 active tasks and 1 schedule due tomorrow.',
              referencedItemCount: 4,
            );

  final bool remoteEnabled;
  final AiSuggestion _suggestion;
  final AiAnswer _answer;

  @override
  bool get isRemoteEnabled => remoteEnabled;

  @override
  Future<AiSuggestion> ingestText(String text) async {
    if (!remoteEnabled) {
      throw const AiRepositoryException('Remote AI is not configured.');
    }

    return AiSuggestion(
      suggestedType: _suggestion.suggestedType,
      title: _suggestion.title.isEmpty ? text.trim() : _suggestion.title,
      confidence: _suggestion.confidence,
      requiresConfirmation: _suggestion.requiresConfirmation,
      extracted: _suggestion.extracted,
    );
  }

  @override
  Future<AiAnswer> askQuestion(String question) async {
    if (!remoteEnabled) {
      throw const AiRepositoryException('Remote AI is not configured.');
    }

    return _answer;
  }
}

class AiRepositoryException implements Exception {
  const AiRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

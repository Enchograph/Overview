import 'dart:convert';
import 'dart:io';

import '../auth/auth_repository.dart';

enum AiSuggestionType { schedule, task, memo }
enum AiErrorCode {
  invalidRequest,
  authorizationRequired,
  speechNotConfigured,
  speechFailed,
  speechEmpty,
  openAiStructuredInvalid,
  openAiAnswerInvalid,
  remoteUnavailable,
  unexpectedResponse,
  requestFailed,
}

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
  Future<String> transcribeAudio({
    required List<int> audioBytes,
    required String mimeType,
    required String locale,
  });
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
    final decoded = await _postJson('/ai/ingest/text', {'text': text});
    if (decoded is Map<String, dynamic>) {
      return AiSuggestion.fromJson(decoded);
    }

    throw const AiRepositoryException(
      code: AiErrorCode.unexpectedResponse,
      message: 'Unexpected response payload',
    );
  }

  @override
  Future<AiAnswer> askQuestion(String question) async {
    final decoded = await _postJson('/ai/ask', {'question': question});
    if (decoded is Map<String, dynamic>) {
      return AiAnswer.fromJson(decoded);
    }

    throw const AiRepositoryException(
      code: AiErrorCode.unexpectedResponse,
      message: 'Unexpected response payload',
    );
  }

  @override
  Future<String> transcribeAudio({
    required List<int> audioBytes,
    required String mimeType,
    required String locale,
  }) async {
    final decoded = await _postJson('/ai/transcribe', {
      'audioBase64': base64Encode(audioBytes),
      'mimeType': mimeType,
      'locale': locale,
    });
    if (decoded is Map<String, dynamic>) {
      return decoded['text'] as String? ?? '';
    }

    throw const AiRepositoryException(
      code: AiErrorCode.unexpectedResponse,
      message: 'Unexpected response payload',
    );
  }

  Future<Object?> _postJson(String path, Map<String, dynamic> payload) async {
    final request = await _httpClient.postUrl(_baseUri.resolve(path));
    request.headers.contentType = ContentType.json;
    await _applyAuthorization(request);
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _parseRepositoryException(response.statusCode, body);
    }

    return jsonDecode(body);
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
    this.transcription = 'Prepare board update tomorrow morning',
    this.failure,
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
  final String transcription;
  final AiRepositoryException? failure;

  @override
  bool get isRemoteEnabled => remoteEnabled;

  @override
  Future<AiSuggestion> ingestText(String text) async {
    if (!remoteEnabled) {
      throw const AiRepositoryException(
        code: AiErrorCode.remoteUnavailable,
        message: 'Remote AI is not configured.',
      );
    }
    if (failure != null) {
      throw failure!;
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
      throw const AiRepositoryException(
        code: AiErrorCode.remoteUnavailable,
        message: 'Remote AI is not configured.',
      );
    }
    if (failure != null) {
      throw failure!;
    }

    return _answer;
  }

  @override
  Future<String> transcribeAudio({
    required List<int> audioBytes,
    required String mimeType,
    required String locale,
  }) async {
    if (!remoteEnabled) {
      throw const AiRepositoryException(
        code: AiErrorCode.remoteUnavailable,
        message: 'Remote AI is not configured.',
      );
    }
    if (failure != null) {
      throw failure!;
    }

    return transcription;
  }
}

class AiRepositoryException implements Exception {
  const AiRepositoryException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details = const [],
  });

  final AiErrorCode code;
  final String message;
  final int? statusCode;
  final List<String> details;

  @override
  String toString() => message;
}

AiRepositoryException _parseRepositoryException(int statusCode, String body) {
  if (body.isNotEmpty) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['error'] as String? ?? 'Request failed';
        final code = _parseAiErrorCode(decoded['code'] as String?, statusCode);
        final details = (decoded['details'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();
        return AiRepositoryException(
          code: code,
          message: message,
          statusCode: statusCode,
          details: details,
        );
      }
    } catch (_) {
      // Fall through to generic mapping when the payload is not valid JSON.
    }
  }

  return AiRepositoryException(
    code: _parseAiErrorCode(null, statusCode),
    message: body.isEmpty ? 'Request failed with $statusCode' : body,
    statusCode: statusCode,
  );
}

AiErrorCode _parseAiErrorCode(String? value, int statusCode) {
  switch (value) {
    case 'invalid_request':
      return AiErrorCode.invalidRequest;
    case 'authorization_required':
      return AiErrorCode.authorizationRequired;
    case 'speech_not_configured':
    case 'azure_speech_not_configured':
      return AiErrorCode.speechNotConfigured;
    case 'speech_failed':
    case 'azure_speech_failed':
      return AiErrorCode.speechFailed;
    case 'speech_empty':
    case 'azure_speech_empty':
      return AiErrorCode.speechEmpty;
    case 'openai_structured_invalid':
      return AiErrorCode.openAiStructuredInvalid;
    case 'openai_answer_invalid':
      return AiErrorCode.openAiAnswerInvalid;
  }

  if (statusCode == 401) {
    return AiErrorCode.authorizationRequired;
  }

  return AiErrorCode.requestFailed;
}

import 'package:flutter/foundation.dart';

import 'ai_repository.dart';

class AiStore extends ChangeNotifier {
  AiStore({required AiRepository repository}) : _repository = repository;

  final AiRepository _repository;

  AiSuggestion? _lastSuggestion;
  AiAnswer? _lastAnswer;
  bool _isSubmitting = false;
  bool _isAnswerSubmitting = false;
  bool _isVoiceSubmitting = false;
  AiRepositoryException? _error;
  AiRepositoryException? _answerError;
  AiRepositoryException? _voiceError;

  AiSuggestion? get lastSuggestion => _lastSuggestion;
  AiAnswer? get lastAnswer => _lastAnswer;
  bool get isSubmitting => _isSubmitting;
  bool get isAnswerSubmitting => _isAnswerSubmitting;
  bool get isVoiceSubmitting => _isVoiceSubmitting;
  AiRepositoryException? get error => _error;
  AiRepositoryException? get answerError => _answerError;
  AiRepositoryException? get voiceError => _voiceError;
  String? get errorMessage => _error?.message;
  String? get answerErrorMessage => _answerError?.message;
  String? get voiceErrorMessage => _voiceError?.message;
  bool get isRemoteEnabled => _repository.isRemoteEnabled;

  Future<void> ingestText(String text) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      _lastSuggestion = await _repository.ingestText(text);
    } catch (error) {
      _error = _asRepositoryException(error);
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSuggestion() {
    _lastSuggestion = null;
    _error = null;
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    _isAnswerSubmitting = true;
    _answerError = null;
    notifyListeners();

    try {
      _lastAnswer = await _repository.askQuestion(question);
    } catch (error) {
      _answerError = _asRepositoryException(error);
    } finally {
      _isAnswerSubmitting = false;
      notifyListeners();
    }
  }

  void clearAnswer() {
    _lastAnswer = null;
    _answerError = null;
    notifyListeners();
  }

  Future<String?> transcribeAudio({
    required List<int> audioBytes,
    required String mimeType,
    required String locale,
  }) async {
    _isVoiceSubmitting = true;
    _voiceError = null;
    notifyListeners();

    try {
      return await _repository.transcribeAudio(
        audioBytes: audioBytes,
        mimeType: mimeType,
        locale: locale,
      );
    } catch (error) {
      _voiceError = _asRepositoryException(error);
      return null;
    } finally {
      _isVoiceSubmitting = false;
      notifyListeners();
    }
  }

  AiRepositoryException _asRepositoryException(Object error) {
    if (error is AiRepositoryException) {
      return error;
    }

    return AiRepositoryException(
      code: AiErrorCode.requestFailed,
      message: error.toString(),
    );
  }
}

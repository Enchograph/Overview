import 'package:flutter/foundation.dart';

import 'ai_repository.dart';

class AiStore extends ChangeNotifier {
  AiStore({required AiRepository repository}) : _repository = repository;

  final AiRepository _repository;

  AiSuggestion? _lastSuggestion;
  AiAnswer? _lastAnswer;
  bool _isSubmitting = false;
  bool _isAnswerSubmitting = false;
  String? _errorMessage;
  String? _answerErrorMessage;

  AiSuggestion? get lastSuggestion => _lastSuggestion;
  AiAnswer? get lastAnswer => _lastAnswer;
  bool get isSubmitting => _isSubmitting;
  bool get isAnswerSubmitting => _isAnswerSubmitting;
  String? get errorMessage => _errorMessage;
  String? get answerErrorMessage => _answerErrorMessage;
  bool get isRemoteEnabled => _repository.isRemoteEnabled;

  Future<void> ingestText(String text) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lastSuggestion = await _repository.ingestText(text);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearSuggestion() {
    _lastSuggestion = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> askQuestion(String question) async {
    _isAnswerSubmitting = true;
    _answerErrorMessage = null;
    notifyListeners();

    try {
      _lastAnswer = await _repository.askQuestion(question);
    } catch (error) {
      _answerErrorMessage = error.toString();
    } finally {
      _isAnswerSubmitting = false;
      notifyListeners();
    }
  }

  void clearAnswer() {
    _lastAnswer = null;
    _answerErrorMessage = null;
    notifyListeners();
  }
}

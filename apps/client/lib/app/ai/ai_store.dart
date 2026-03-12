import 'package:flutter/foundation.dart';

import 'ai_repository.dart';

class AiStore extends ChangeNotifier {
  AiStore({required AiRepository repository}) : _repository = repository;

  final AiRepository _repository;

  AiSuggestion? _lastSuggestion;
  bool _isSubmitting = false;
  String? _errorMessage;

  AiSuggestion? get lastSuggestion => _lastSuggestion;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
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
}

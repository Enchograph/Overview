import 'package:flutter/foundation.dart';

import 'speech_input_service.dart';

class SpeechInputStore extends ChangeNotifier {
  SpeechInputStore({required SpeechInputService service}) : _service = service;

  final SpeechInputService _service;

  bool _isRecording = false;
  bool _hasPermission = true;
  String? _errorMessage;

  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;

  Future<bool> startRecording() async {
    _errorMessage = null;
    final hasPermission = await _service.hasPermission();
    _hasPermission = hasPermission;
    if (!hasPermission) {
      _errorMessage = 'Microphone permission is not granted.';
      notifyListeners();
      return false;
    }

    try {
      await _service.startRecording();
      _isRecording = true;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<RecordedAudio?> stopRecording() async {
    try {
      final audio = await _service.stopRecording();
      _isRecording = false;
      notifyListeners();
      return audio;
    } catch (error) {
      _errorMessage = error.toString();
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

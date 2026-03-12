import 'package:flutter/foundation.dart';

import 'speech_input_service.dart';

class SpeechInputStore extends ChangeNotifier {
  SpeechInputStore({required SpeechInputService service}) : _service = service;

  final SpeechInputService _service;

  bool _isRecording = false;
  bool _hasPermission = true;
  SpeechInputException? _error;

  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;
  SpeechInputException? get error => _error;
  String? get errorMessage => _error?.message;

  Future<bool> startRecording() async {
    _error = null;
    final hasPermission = await _service.hasPermission();
    _hasPermission = hasPermission;
    if (!hasPermission) {
      _error = const SpeechInputException(
        code: SpeechInputErrorCode.microphonePermissionDenied,
        message: 'Microphone permission is not granted.',
      );
      notifyListeners();
      return false;
    }

    try {
      await _service.startRecording();
      _isRecording = true;
      notifyListeners();
      return true;
    } catch (error) {
      _error = error is SpeechInputException
          ? error
          : SpeechInputException(
              code: SpeechInputErrorCode.recordingStartFailed,
              message: error.toString(),
            );
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
      _error = error is SpeechInputException
          ? error
          : SpeechInputException(
              code: SpeechInputErrorCode.recordingStopFailed,
              message: error.toString(),
            );
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

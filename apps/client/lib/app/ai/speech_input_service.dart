import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordedAudio {
  const RecordedAudio({
    required this.bytes,
    required this.mimeType,
  });

  final List<int> bytes;
  final String mimeType;
}

abstract class SpeechInputService {
  bool get isRecording;

  Future<bool> hasPermission();

  Future<void> startRecording();

  Future<RecordedAudio?> stopRecording();
}

class AudioRecorderSpeechInputService implements SpeechInputService {
  AudioRecorderSpeechInputService({
    AudioRecorder? recorder,
    Future<Directory> Function()? temporaryDirectoryProvider,
  })  : _recorder = recorder ?? AudioRecorder(),
        _temporaryDirectoryProvider =
            temporaryDirectoryProvider ?? getTemporaryDirectory;

  final AudioRecorder _recorder;
  final Future<Directory> Function() _temporaryDirectoryProvider;
  String? _currentPath;
  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> startRecording() async {
    final directory = await _temporaryDirectoryProvider();
    final path =
        '${directory.path}/overview-voice-${DateTime.now().microsecondsSinceEpoch}.wav';
    _currentPath = path;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _isRecording = true;
  }

  @override
  Future<RecordedAudio?> stopRecording() async {
    final path = await _recorder.stop();
    _isRecording = false;
    final resolvedPath = path ?? _currentPath;
    _currentPath = null;
    if (resolvedPath == null) {
      return null;
    }

    final file = File(resolvedPath);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    await file.delete();
    return RecordedAudio(
      bytes: bytes,
      mimeType: 'audio/wav',
    );
  }
}

class FakeSpeechInputService implements SpeechInputService {
  FakeSpeechInputService({
    this.permissionGranted = true,
    this.recordedAudio = const RecordedAudio(
      bytes: [1, 2, 3],
      mimeType: 'audio/wav',
    ),
  });

  final bool permissionGranted;
  final RecordedAudio recordedAudio;
  bool _isRecording = false;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<bool> hasPermission() async => permissionGranted;

  @override
  Future<void> startRecording() async {
    if (!permissionGranted) {
      throw const SpeechInputException('Microphone permission is not granted.');
    }

    _isRecording = true;
  }

  @override
  Future<RecordedAudio?> stopRecording() async {
    if (!_isRecording) {
      return null;
    }

    _isRecording = false;
    return recordedAudio;
  }
}

class SpeechInputException implements Exception {
  const SpeechInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

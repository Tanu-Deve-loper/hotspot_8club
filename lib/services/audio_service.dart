import 'dart:async';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  Timer? _amplitudeTimer;
  int _recordDuration = 0;
  bool _isCurrentlyRecording = false;

  // Check and request microphone permission
  Future<bool> checkPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  // Start recording with amplitude stream
  Future<void> startRecording(
    Function(int) onDurationUpdate,
    Function(double) onAmplitudeUpdate,
  ) async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/audio_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      _isCurrentlyRecording = true;

      // Timer for duration
      _recordDuration = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordDuration++;
        onDurationUpdate(_recordDuration);
      });

      // Timer for amplitude (real-time waveform)
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (!_isCurrentlyRecording) {
          timer.cancel();
          return;
        }
        
        try {
          final amplitude = await _recorder.getAmplitude();
          // Normalize amplitude to 0.0-1.0 range
          final normalizedAmplitude = (amplitude.current + 50) / 50;
          onAmplitudeUpdate(normalizedAmplitude.clamp(0.0, 1.0));
        } catch (e) {
          // Ignore amplitude errors during recording
        }
      });
    } catch (e) {
      throw Exception('Failed to start recording: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      _isCurrentlyRecording = false;
      _timer?.cancel();
      _amplitudeTimer?.cancel();
      final path = await _recorder.stop();
      return path;
    } catch (e) {
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> cancelRecording() async {
    try {
      _isCurrentlyRecording = false;
      _timer?.cancel();
      _amplitudeTimer?.cancel();
      await _recorder.stop();
      _recordDuration = 0;
    } catch (e) {
      throw Exception('Failed to cancel recording: $e');
    }
  }

  int get recordDuration => _recordDuration;
  bool get isRecording => _isCurrentlyRecording;

  void dispose() {
    _isCurrentlyRecording = false;
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _recorder.dispose();
  }
}

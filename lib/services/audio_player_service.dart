import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  // Play audio
  Future<void> play(String filePath) async {
    try {
      await _player.play(DeviceFileSource(filePath));
      _isPlaying = true;
    } catch (e) {
      throw Exception('Failed to play audio: $e');
    }
  }

  // Pause audio
  Future<void> pause() async {
    await _player.pause();
    _isPlaying = false;
  }

  // Stop audio
  Future<void> stop() async {
    await _player.stop();
    _isPlaying = false;
  }

  // Listen to player state
  Stream<PlayerState> get onPlayerStateChanged => _player.onPlayerStateChanged;

  // Dispose
  void dispose() {
    _player.dispose();
  }
}

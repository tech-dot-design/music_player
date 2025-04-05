import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

class AudioPlayerService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentFilePath;

  // Stream listeners
  Stream<Duration> get onPositionChanged => _audioPlayer.onPositionChanged;
  Stream<Duration?> get onDurationChanged => _audioPlayer.onDurationChanged;

  // 🎵 Pick and Play Audio
  Future<String?> pickAndPlayAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio, // Allow only audio files
    );

    if (result != null && result.files.single.path != null) {
      _currentFilePath = result.files.single.path!;
      await _audioPlayer.setSourceDeviceFile(_currentFilePath!);
      await _audioPlayer.resume();
      return _currentFilePath!.split('/').last;
    }
    return null;
  }

  // 🎵 Play Audio
  Future<void> playAudio() async {
    if (_currentFilePath != null) {
      await _audioPlayer.resume();
    }
  }

  // ⏸ Pause Audio
  Future<void> pauseAudio() async {
    await _audioPlayer.pause();
  }

  // ⏹ Stop Audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  // 🔊 Set Volume
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // ⏩ Seek to specific position
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }
}
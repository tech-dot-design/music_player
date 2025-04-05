import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  void _toggleDarkMode(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('darkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: MainScreen(toggleDarkMode: _toggleDarkMode, isDarkMode: _isDarkMode),
    );
  }
}

class MainScreen extends StatelessWidget {
  final Function(bool) toggleDarkMode;
  final bool isDarkMode;

  MainScreen({required this.toggleDarkMode, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Music Player")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to Music Player",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MusicPlayerScreen()),
              ),
              child: Text("Open Player"),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Dark Mode"),
                Switch(value: isDarkMode, onChanged: toggleDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  double _volume = 0.5;
  String _currentFileName = "No file selected";
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadPlayerState();
    _audioService.audioPlayer.onPositionChanged.listen(_updatePosition);
    _audioService.audioPlayer.onDurationChanged.listen(_updateDuration);
  }

  void _loadPlayerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentFileName = prefs.getString('currentFileName') ?? "No file selected";
      _currentPosition = Duration(seconds: prefs.getInt('currentPosition') ?? 0);
      _totalDuration = Duration(seconds: prefs.getInt('totalDuration') ?? 0);
      _volume = prefs.getDouble('volume') ?? 0.5;
      _isPlaying = prefs.getBool('isPlaying') ?? false;
    });

    if (_isPlaying) {
      _audioService.resumeAudio();
    }
  }

  void _updatePosition(Duration position) {
    setState(() {
      _currentPosition = position;
    });
    _savePlayerState();
  }

  void _updateDuration(Duration? duration) {
    setState(() {
      _totalDuration = duration ?? Duration.zero;
    });
    _savePlayerState();
  }

  void _savePlayerState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('currentFileName', _currentFileName);
    prefs.setInt('currentPosition', _currentPosition.inSeconds);
    prefs.setInt('totalDuration', _totalDuration.inSeconds);
    prefs.setDouble('volume', _volume);
    prefs.setBool('isPlaying', _isPlaying);
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString();
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Now Playing: $_currentFileName")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              String? selectedFile = await _audioService.pickAndPlayAudio();
              if (selectedFile != null) {
                setState(() {
                  _currentFileName = selectedFile;
                });
                _savePlayerState();
              }
            },
            child: Text("Select & Play Audio"),
          ),
          Slider(
            value: _currentPosition.inSeconds.toDouble(),
            min: 0.0,
            max: _totalDuration.inSeconds.toDouble(),
            onChanged: (value) async {
              await _audioService.seekTo(Duration(seconds: value.toInt()));
            },
          ),
          Text("${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}"),
          IconButton(
            onPressed: () {
              setState(() {
                if (_isPlaying) {
                  _audioService.pauseAudio();
                  _isPlaying = false;
                } else {
                  _audioService.resumeAudio();
                  _isPlaying = true;
                }
                _savePlayerState();
              });
            },
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 40,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _audioService.stopAudio();
                _currentFileName = "No file selected";
                _currentPosition = Duration.zero;
                _totalDuration = Duration.zero;
                _isPlaying = false;
              });
              _savePlayerState();
            },
            child: Text("Stop"),
          ),
          Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                _volume = value;
                _audioService.setVolume(value);
              });
              _savePlayerState();
            },
          ),
        ],
      ),
    );
  }
}

class AudioPlayerService {
  final AudioPlayer audioPlayer = AudioPlayer();
  String? _currentFilePath;

  Future<String?> pickAndPlayAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      _currentFilePath = result.files.single.path!;
      await audioPlayer.setSourceDeviceFile(_currentFilePath!);
      await audioPlayer.resume();
      return _currentFilePath!.split('/').last;
    }
    return null;
  }

  Future<void> playAudio() async => await audioPlayer.resume();
  Future<void> pauseAudio() async => await audioPlayer.pause();
  Future<void> stopAudio() async => await audioPlayer.stop();
  Future<void> setVolume(double volume) async => await audioPlayer.setVolume(volume);
  Future<void> seekTo(Duration position) async => await audioPlayer.seek(position);
  Future<void> resumeAudio() async => await audioPlayer.resume();
}
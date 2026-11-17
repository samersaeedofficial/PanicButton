import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<String?> recordPanicClip({int durationSeconds = 10}) async {
    try {
      if (!await _recorder.hasPermission()) {
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/panic_audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final filePath =
          '${audioDir.path}/sos_${DateTime.now().millisecondsSinceEpoch}.m4a';

      _isRecording = true;
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: filePath,
      );

      await Future.delayed(Duration(seconds: durationSeconds));

      final recordedPath = await _recorder.stop();
      _isRecording = false;
      return recordedPath;
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  Future<void> playClip(String path) async {
    try {
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {}
  }

  Future<void> stopPlayback() async {
    await _player.stop();
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}

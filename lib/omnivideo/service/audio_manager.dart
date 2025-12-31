import 'package:just_audio/just_audio.dart';

class AudioManager {
  final Map<String, AudioPlayer> _players = {};

  Future<void> addTrack(String id, String path) async {
    final player = AudioPlayer();
    await player.setFilePath(path);
    _players[id] = player;
  }

  void play(String id) {
    _players[id]?.play();
  }

  void pause(String id) {
    _players[id]?.pause();
  }

  void setVolume(String id, double volume) {
    _players[id]?.setVolume(volume);
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../model/timeline_item.dart';
import '../servuices/audio_manager.dart';
import '../servuices/clip_controller.dart';

class AudioLibrarySheet extends StatefulWidget {
  final ClipController clipController;
  final AudioManager audioManager;
  final Duration insertPosition;

  const AudioLibrarySheet({
    super.key,
    required this.clipController,
    required this.audioManager,
    required this.insertPosition,
  });

  @override
  State<AudioLibrarySheet> createState() => _AudioLibrarySheetState();
}

class _AudioLibrarySheetState extends State<AudioLibrarySheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _previewPlayer = AudioPlayer();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  String? _currentlyPlayingId;

  List<SongModel> _deviceSongs = [];
  bool _isLoadingDevice = true;

  List<Map<String, dynamic>> _deezerSongs = [];
  bool _isLoadingOnline = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _requestPermissionAndLoadDevice();
    _loadDeezerTrending();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndLoadDevice() async {
    setState(() => _isLoadingDevice = true);

    var status = await Permission.storage.status;
    if (!status.isGranted) status = await Permission.storage.request();
    if (!status.isGranted) status = await Permission.audio.request();
    if (!status.isGranted)
      status = await Permission.manageExternalStorage.request();

    if (status.isGranted) {
      _deviceSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Cannot load device music.'),
          ),
        );
      }
    }

    setState(() => _isLoadingDevice = false);
  }

  Future<void> _loadDeezerTrending() async {
    setState(() => _isLoadingOnline = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.deezer.com/chart/0/tracks'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _deezerSongs = List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Deezer load failed: $e');
    }
    setState(() => _isLoadingOnline = false);
  }

  Future<void> _previewAudio(String url, String id) async {
    if (_currentlyPlayingId == id) {
      if (_previewPlayer.playing) {
        await _previewPlayer.pause();
      } else {
        await _previewPlayer.play();
      }
    } else {
      await _previewPlayer.stop();
      await _previewPlayer.setUrl(url);
      await _previewPlayer.play();
      _currentlyPlayingId = id;
    }
    setState(() {});
  }

  Future<void> _addAudio(String pathOrUrl, Duration duration) async {
    File file;
    if (pathOrUrl.startsWith('http')) {
      final dir = await getTemporaryDirectory();
      final response = await http.get(Uri.parse(pathOrUrl));
      file = File(
        '${dir.path}/online_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );
      await file.writeAsBytes(response.bodyBytes);
    } else {
      file = File(pathOrUrl);
    }

    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.audio,
      file: file,
      startTime: widget.insertPosition,
      duration: duration,
      originalDuration: duration,
      trimStart: Duration.zero,
      volume: 1.0,
    );

    await widget.clipController.addAudioClip(item);
    await _previewPlayer.stop();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      builder:
          (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 5,
                  color: Colors.grey,
                ),
                const Text(
                  'Add Music',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search music',
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder:
                        (_, i) => Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Featured $i',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Trending'),
                    Tab(text: 'Device'),
                    Tab(text: 'TikTok'),
                    Tab(text: 'Favorites'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildDeezerList(),
                      _buildDeviceList(),
                      _buildPlaceholder('TikTok Sounds'),
                      _buildPlaceholder('Favorites'),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDeezerList() {
    if (_isLoadingOnline) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_deezerSongs.isEmpty) {
      return const Center(
        child: Text('No songs found', style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      itemCount: _deezerSongs.length,
      itemBuilder: (_, i) {
        final song = _deezerSongs[i];
        final id = song['id'].toString();
        final isCurrent = _currentlyPlayingId == id;

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song['album']['cover_small'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(
            song['title'],
            style: const TextStyle(color: Colors.white),
          ),
          subtitle: Text(
            song['artist']['name'],
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _previewPlayer.playing && isCurrent
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: isCurrent ? const Color(0xFF00D9FF) : Colors.white70,
                ),
                onPressed: () => _previewAudio(song['preview'], id),
              ),
              if (isCurrent)
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D9FF),
                  ),
                  onPressed:
                      () => _addAudio(
                        song['preview'],
                        const Duration(seconds: 30),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    if (_isLoadingDevice) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
      );
    }
    if (_deviceSongs.isEmpty) {
      return const Center(
        child: Text(
          'No music found on device',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: _deviceSongs.length,
      itemBuilder: (_, i) {
        final song = _deviceSongs[i];
        final id = song.id.toString();
        final isCurrent = _currentlyPlayingId == id;

        return ListTile(
          leading: FutureBuilder<List<int>?>(
            future: _audioQuery.queryArtwork(song.id, ArtworkType.AUDIO),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              if (snapshot.hasData && snapshot.data != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(snapshot.data!),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                );
              } else {
                // Default music note icon if no artwork is available
                return const Icon(Icons.music_note, color: Colors.white70);
              }
            },
          ),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            song.artist ?? 'Unknown',
            style: const TextStyle(color: Colors.white54),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _previewPlayer.playing && isCurrent
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: isCurrent ? const Color(0xFF00D9FF) : Colors.white70,
                ),
                onPressed: () => _previewAudio('file://${song.data}', id),
              ),
              if (isCurrent)
                IconButton(
                  icon: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00D9FF),
                  ),
                  onPressed:
                      () => _addAudio(
                        song.data,
                        Duration(milliseconds: song.duration ?? 0),
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String message) {
    return Center(
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}

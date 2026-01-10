// audio_library_sheet.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../model/audio_track.dart';
import '../provider/video_editor_provider.dart';

class AudioLibrarySheet extends StatefulWidget {
  final Duration insertPosition;

  const AudioLibrarySheet({
    super.key,
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
    _tabController = TabController(length: 5, vsync: this);
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
    var status = await Permission.audio.request();
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      _deviceSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        ignoreCase: true,
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission denied – cannot load device music')),
        );
      }
    }
    setState(() => _isLoadingDevice = false);
  }

  Future<void> _loadDeezerTrending() async {
    setState(() => _isLoadingOnline = true);
    try {
      final response = await http.get(Uri.parse('https://api.deezer.com/chart/0/tracks'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _deezerSongs = List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
    } catch (e) {
      debugPrint('Deezer load failed: $e');
    }
    setState(() => _isLoadingOnline = false);
  }

  Future<void> _previewAudio(String urlOrPath, String id) async {
    if (_currentlyPlayingId == id) {
      if (_previewPlayer.playing) {
        await _previewPlayer.pause();
      } else {
        await _previewPlayer.play();
      }
      setState(() {});
      return;
    }

    try {
      await _previewPlayer.stop();
      if (urlOrPath.startsWith('http')) {
        await _previewPlayer.setUrl(urlOrPath);
      } else {
        await _previewPlayer.setFilePath(urlOrPath);
      }
      await _previewPlayer.play();
      _currentlyPlayingId = id;
    } catch (e) {
      debugPrint('Preview failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not preview track')),
        );
      }
      _currentlyPlayingId = null;
    }
    setState(() {});
  }

  // Helper: Copy file to app's temp directory and return safe File
  Future<File> _copyToAppDirectory(File originalFile, String prefix) async {
    final dir = await getTemporaryDirectory();
    final extension = originalFile.path.split('.').last;
    final newPath = '${dir.path}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    return await originalFile.copy(newPath);
  }

  Future<void> _addAudio(File safeFile, Duration duration) async {
    final provider = context.read<VideoEditorProvider>();

    if (provider.selectedAudioTrack != null) {
      await provider.replaceAudioTrack(
        oldTrack: provider.selectedAudioTrack!,
        newFile: safeFile,
      );
    } else {
      await provider.addAudio(  // ← calls the fixed version above
        file: safeFile,
        start: widget.insertPosition,
      );
    }

    await _previewPlayer.stop();

    // Correct close: return to context toolbar
    provider
      ..showBottomSheet = false
      ..showContextToolbar = true
      ..notifyListeners();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio added to timeline!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VideoEditorProvider>(context, listen: false);
    final selectedAudio = provider.selectedAudioTrack;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 5,
            color: Colors.grey,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Audio',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search audio',
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Trending'),
              Tab(text: 'Hits'),
              Tab(text: 'TikTok'),
              Tab(text: 'Device'),
              Tab(text: 'Import'),
            ],
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDeezerList(),
                _buildPlaceholder('Hits'),
                _buildPlaceholder('TikTok Sounds'),
                _buildDeviceList(),
                _buildImportTab(provider, selectedAudio),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeezerList() {
    if (_isLoadingOnline) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_deezerSongs.isEmpty) return const Center(child: Text('No tracks found', style: TextStyle(color: Colors.white70)));

    return ListView.builder(
      itemCount: _deezerSongs.length,
      itemBuilder: (_, i) {
        final song = _deezerSongs[i];
        final id = song['id'].toString();
        final isPlaying = _currentlyPlayingId == id && _previewPlayer.playing;

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song['album']['cover_small'],
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white70),
            ),
          ),
          title: Text(song['title'], style: const TextStyle(color: Colors.white)),
          subtitle: Text(song['artist']['name'], style: const TextStyle(color: Colors.white54)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white70),
                onPressed: () => _previewAudio(song['preview'], id),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF00D9FF)),
                onPressed: () async {
                  final dir = await getTemporaryDirectory();
                  final response = await http.get(Uri.parse(song['preview']));
                  final file = File('${dir.path}/deezer_${song['id']}.mp3');
                  await file.writeAsBytes(response.bodyBytes);
                  await _addAudio(file, const Duration(seconds: 30));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    if (_isLoadingDevice) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_deviceSongs.isEmpty) return const Center(child: Text('No music on device', style: TextStyle(color: Colors.white70)));

    return ListView.builder(
      itemCount: _deviceSongs.length,
      itemBuilder: (_, i) {
        final song = _deviceSongs[i];
        final id = song.id.toString();
        final isPlaying = _currentlyPlayingId == id && _previewPlayer.playing;
        final duration = Duration(milliseconds: song.duration ?? 0);
        if (duration == Duration.zero) return const SizedBox.shrink();

        return ListTile(
          onTap: () async {
            final originalFile = File(song.data);
            final safeFile = await _copyToAppDirectory(originalFile, 'device');
            await _addAudio(safeFile, duration);
          },
          leading: FutureBuilder<Uint8List?>(
            future: _audioQuery.queryArtwork(song.id, ArtworkType.AUDIO),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(snapshot.data!, width: 50, height: 50, fit: BoxFit.cover),
                );
              }
              return const Icon(Icons.music_note, color: Colors.white70, size: 40);
            },
          ),
          title: Text(song.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(song.artist ?? 'Unknown', style: const TextStyle(color: Colors.white54)),
          trailing: IconButton(
            icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white70),
            onPressed: () => _previewAudio(song.data, id),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String title) {
    return Center(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)));
  }

  Widget _buildImportTab(VideoEditorProvider provider, AudioTrack? selectedAudio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.folder_open, color: Colors.white),
          label: Text(
            selectedAudio != null ? 'Replace Selected Audio' : 'Pick Audio from Device',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
          onPressed: () async {
            try {
              final result = await FilePicker.platform.pickFiles(type: FileType.audio);

              if (result == null) return;

              File safeFile;

              if (result.files.single.bytes != null) {
                final dir = await getTemporaryDirectory();
                final ext = result.files.single.extension ?? 'mp3';
                safeFile = File('${dir.path}/picked_${DateTime.now().millisecondsSinceEpoch}.$ext');
                await safeFile.writeAsBytes(result.files.single.bytes!);
              } else if (result.files.single.path != null) {
                final original = File(result.files.single.path!);
                safeFile = await _copyToAppDirectory(original, 'import');
              } else {
                return;
              }

              if (selectedAudio != null) {
                await provider.replaceAudioTrack(oldTrack: selectedAudio, newFile: safeFile);
              } else {
                await provider.addAudio(file: safeFile, start: widget.insertPosition);
              }

              // ONLY CLOSE THE SHEET — DO NOT Navigator.pop!
              provider
                ..showBottomSheet = false
                ..showContextToolbar = true;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Audio added to timeline!')),
              );
            } catch (e) {
              debugPrint('Picker error: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed: $e')),
              );
            }
          },
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.audiotrack, color: Colors.white),
          label: const Text('Extract Audio from Selected Video', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          onPressed: () async {
            if (provider.videoTracks.isNotEmpty && provider.selectedTrackIndex >= 0) {
              await provider.extractAudioFromSelectedClip();

              provider
                ..showBottomSheet = false
                ..showContextToolbar = true;

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Original audio extracted!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select a video clip first')),
              );
            }
          },
        ),
      ],
    );
  }
}
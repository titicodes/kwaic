import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kwaic/nes_scr/screen/new.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../omnivideo/enum/enums.dart';
import '../../omnivideo/views/edit_home_view.dart';
import '../../omnivideo/views/video_editor_screen.dart';
import 'video_editor_screen.dart';

class VideoSelectionScreen extends StatefulWidget {
  const VideoSelectionScreen({super.key});

  @override
  State<VideoSelectionScreen> createState() => _VideoSelectionScreenState();
}

class _VideoSelectionScreenState extends State<VideoSelectionScreen>
    with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _albumTabController;

  final List<PickedAsset> _selectedAssets = [];
  List<AssetEntity> _deviceVideos = [];
  List<AssetEntity> _devicePhotos = [];

  // Reliable public short sample videos
  final List<String> libraryClips = [
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4",
  ];

  String _projectName = 'Untitled Project';

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _albumTabController = TabController(
      length: 2,
      vsync: this,
    ); // Videos + Photos
    _loadDeviceMedia();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _albumTabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeviceMedia() async {
    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) return;

    final videos = await PhotoManager.getAssetPathList(type: RequestType.video);
    final photos = await PhotoManager.getAssetPathList(type: RequestType.image);

    if (videos.isNotEmpty) {
      final List<AssetEntity> allVideos = [];
      for (final path in videos) {
        final assets = await path.getAssetListPaged(page: 0, size: 1000);
        allVideos.addAll(assets);
      }
      _deviceVideos = allVideos;
    }

    if (photos.isNotEmpty) {
      final List<AssetEntity> allPhotos = [];
      for (final path in photos) {
        final assets = await path.getAssetListPaged(page: 0, size: 1000);
        allPhotos.addAll(assets);
      }
      _devicePhotos = allPhotos;
    }

    setState(() {});
  }

  void _toggleSelection(PickedAsset asset) {
    setState(() {
      final index = _selectedAssets.indexWhere((e) => e.id == asset.id);
      if (index >= 0) {
        _selectedAssets.removeAt(index);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  Future<List<Map<String, dynamic>>> _generateThumbnails(List<XFile> xfiles) async {
    final List<Map<String, dynamic>> videosWithThumbs = [];
    for (final xfile in xfiles) {
      final thumb = await VideoThumbnail.thumbnailData(
        video: xfile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 128,
        quality: 75,
      );
      videosWithThumbs.add({
        'file': xfile,
        'thumbnail': thumb,
      });
    }
    return videosWithThumbs;
  }

// In _startEditing method of VideoSelectionScreen
  Future<void> _startEditing() async {
    final videoAssets = _selectedAssets.where(
          (a) => a.source == AssetSource.localVideo || a.source == AssetSource.onlineVideo,
    ).toList();

    if (videoAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one video')),
      );
      return;
    }

    final List<XFile> xfiles = [];
    for (final picked in videoAssets) {
      if (picked.source == AssetSource.localVideo) {
        final entity = _deviceVideos.firstWhere((e) => e.id == picked.id);
        final file = await entity.file;
        if (file != null) xfiles.add(XFile(file.path));
      } else if (picked.source == AssetSource.onlineVideo) {
        xfiles.add(XFile(picked.pathOrUrl));
      }
    }

    if (xfiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to prepare videos')),
      );
      return;
    }

    final videosWithThumbs = await _generateThumbnails(xfiles);

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoEditorScreens(
          videosWithThumbs: videosWithThumbs,
          projectId: DateTime.now().millisecondsSinceEpoch.toString(),
          projectName: _projectName,
        ),
      ),
    );
  }

  TabBar _styledTabBar({
    required TabController controller,
    required List<Tab> tabs,
  }) {
    return TabBar(
      controller: controller,
      tabs: tabs,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAlbumTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _styledTabBar(
            controller: _albumTabController,
            tabs: const [Tab(text: "Videos"), Tab(text: "Photos")],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _albumTabController,
            children: [_buildVideoGrid(), _buildPhotoGrid()],
          ),
        ),
      ],
    );
  }

  // Identical to AssetSelectionScreen
  Widget _buildVideoGrid() {
    if (_deviceVideos.isEmpty) {
      return const Center(child: Text("No videos found"));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _deviceVideos.length,
      itemBuilder: (_, index) {
        final entity = _deviceVideos[index];
        return FutureBuilder<Uint8List?>(
          future: entity.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();
            final asset = PickedAsset(
              id: entity.id,
              pathOrUrl: entity.id,
              source: AssetSource.localVideo,
            );
            final selected = _selectedAssets.any((e) => e.id == asset.id);
            return GestureDetector(
              onTap: () => _toggleSelection(asset),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "${entity.videoDuration.inMinutes}:${(entity.videoDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle, color: Colors.blue),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Identical to AssetSelectionScreen
  Widget _buildPhotoGrid() {
    if (_devicePhotos.isEmpty) {
      return const Center(child: Text("No photos found"));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: _devicePhotos.length,
      itemBuilder: (_, index) {
        final entity = _devicePhotos[index];
        return FutureBuilder<Uint8List?>(
          future: entity.thumbnailDataWithSize(const ThumbnailSize(300, 300)),
          builder: (_, snap) {
            if (!snap.hasData) return const SizedBox();
            final asset = PickedAsset(
              id: entity.id,
              pathOrUrl: entity.id,
              source: AssetSource.localPhoto,
            );
            final selected = _selectedAssets.any((e) => e.id == asset.id);
            return GestureDetector(
              onTap: () => _toggleSelection(asset),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle, color: Colors.blue),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Library Tab - now works reliably
  Widget _buildLibraryTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: libraryClips.length,
      itemBuilder: (_, index) {
        final url = libraryClips[index];
        return FutureBuilder<Uint8List?>(
          future: VideoThumbnail.thumbnailData(
            video: url,
            imageFormat: ImageFormat.JPEG,
            maxWidth: 300,
            quality: 75,
          ),
          builder: (_, snap) {
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final asset = PickedAsset(
              id: url,
              pathOrUrl: url,
              source: AssetSource.onlineVideo,
            );
            final selected = _selectedAssets.any((e) => e.id == asset.id);
            return GestureDetector(
              onTap: () => _toggleSelection(asset),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      snap.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  if (selected)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(Icons.check_circle, color: Colors.blue),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: () async {
            final controller = TextEditingController(text: _projectName);
            final result = await showDialog<String>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text('Project Name'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed:
                            () => Navigator.pop(context, controller.text),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
            );
            if (result != null && result.isNotEmpty) {
              setState(() => _projectName = result);
            }
          },
          child: Text(
            _projectName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          if (_selectedAssets.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selectedAssets.clear()),
              child: const Text('Clear'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: _styledTabBar(
                    controller: _mainTabController,
                    tabs: const [
                      Tab(text: "Album"),
                      Tab(text: "Username"),
                      Tab(text: "Library"),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _mainTabController,
                children: [
                  _buildAlbumTab(),
                  const Center(child: Text("Username Content")),
                  _buildLibraryTab(),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child:
                  _selectedAssets.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _startEditing,
                            child: Text(
                              "Start Editing (${_selectedAssets.where((a) => a.source != AssetSource.localPhoto).length})",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

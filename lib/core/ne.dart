//
//
// import 'dart:io' show File, Platform;
// import 'dart:math' as math;
// import 'dart:typed_data';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:collection/collection.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_min_gpl/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_min_gpl/return_code.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:video_player/video_player.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
//
// void main() => runApp(const VideoEditorApp());
//
// class VideoEditorApp extends StatelessWidget {
//   const VideoEditorApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'CapCut Clone',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.dark,
//         scaffoldBackgroundColor: Colors.black,
//         primaryColor: const Color(0xFF00C9CC),
//         useMaterial3: true,
//       ),
//       home: const VideoEditorScreen(),
//     );
//   }
// }
//
// /* ------------------------------------------------------------------ */
// /* MODELS */
// /* ------------------------------------------------------------------ */
// enum TimelineItemType { video, audio, image, text }
//
// class TimelineItem {
//   final String id;
//   final TimelineItemType type;
//   final File? file;
//   String? text;
//   Duration startTime;
//   Duration duration;
//   Duration originalDuration;
//   Duration trimStart;
//   Duration trimEnd;
//   double speed;
//   double volume;
//   Color? textColor;
//   double? fontSize;
//   double? x;
//   double? y;
//   double rotation;
//   double scale;
//   String? effect;
//   final List<String> thumbnailPaths = [];
//   List<double>? waveformData;
//   Rect? cropRect;
//
//   TimelineItem({
//     required this.id,
//     required this.type,
//     this.file,
//     this.text,
//     required this.startTime,
//     required this.duration,
//     required this.originalDuration,
//     Duration? trimStart,
//     Duration? trimEnd,
//     this.speed = 1.0,
//     this.volume = 1.0,
//     this.textColor = Colors.white,
//     this.fontSize = 32,
//     this.x,
//     this.y,
//     this.rotation = 0.0,
//     this.scale = 1.0,
//     this.effect,
//     this.cropRect,
//   })  : trimStart = trimStart ?? Duration.zero,
//         trimEnd = trimEnd ?? originalDuration;
//
//   TimelineItem copyWith({
//     String? id,
//     Duration? startTime,
//     Duration? duration,
//     Duration? trimStart,
//     Duration? trimEnd,
//     double? speed,
//     double? volume,
//     String? text,
//     Color? textColor,
//     double? fontSize,
//     double? x,
//     double? y,
//     double? rotation,
//     double? scale,
//     String? effect,
//     Rect? cropRect,
//   }) {
//     return TimelineItem(
//       id: id ?? this.id,
//       type: type,
//       file: file,
//       text: text ?? this.text,
//       startTime: startTime ?? this.startTime,
//       duration: duration ?? this.duration,
//       originalDuration: originalDuration,
//       trimStart: trimStart ?? this.trimStart,
//       trimEnd: trimEnd ?? this.trimEnd,
//       speed: speed ?? this.speed,
//       volume: volume ?? this.volume,
//       textColor: textColor ?? this.textColor,
//       fontSize: fontSize ?? this.fontSize,
//       x: x ?? this.x,
//       y: y ?? this.y,
//       rotation: rotation ?? this.rotation,
//       scale: scale ?? this.scale,
//       effect: effect ?? this.effect,
//       cropRect: cropRect ?? this.cropRect,
//     )..thumbnailPaths.addAll(thumbnailPaths);
//   }
// }
//
// /* ------------------------------------------------------------------ */
// /* Duration helpers */
// /* ------------------------------------------------------------------ */
// extension DurationMath on Duration {
//   Duration multiply(double factor) =>
//       Duration(milliseconds: (inMilliseconds * factor).round());
//
//   Duration divide(double divisor) => divisor == 0
//       ? this
//       : Duration(milliseconds: (inMilliseconds / divisor).round());
//
//   Duration clamp(Duration min, Duration max) {
//     if (this < min) return min;
//     if (this > max) return max;
//     return this;
//   }
// }
//
// /* ------------------------------------------------------------------ */
// /* MAIN SCREEN */
// /* ------------------------------------------------------------------ */
// class VideoEditorScreen extends StatefulWidget {
//   const VideoEditorScreen({super.key});
//
//   @override
//   State<VideoEditorScreen> createState() => _VideoEditorScreenState();
// }
//
// class _VideoEditorScreenState extends State<VideoEditorScreen>
//     with TickerProviderStateMixin {
//   String _mode = 'Edit';
//   List<TimelineItem> _items = [];
//   List<TimelineItem> _audioItems = [];
//   List<TimelineItem> _overlayItems = [];
//   List<TimelineItem> _textItems = [];
//   TimelineItem? _selected;
//   Duration _currentPosition = Duration.zero;
//   Duration _totalDuration = Duration.zero;
//   final Map<String, VideoPlayerController> _controllers = {};
//   final Map<String, AudioPlayer> _audioControllers = {};
//   final Map<String, Duration> _audioPositions = {};
//   VideoPlayerController? _activePreviewController;
//   TimelineItem? _activeItem;
//   bool _playing = false;
//   final ImagePicker _picker = ImagePicker();
//   final ScrollController _timelineScrollController = ScrollController();
//   final GlobalKey _previewKey = GlobalKey();
//   late Ticker _playbackTicker;
//   int _lastFrameTime = 0;
//   double _pixelsPerSecond = 100.0;
//   Offset? _lastFocalPoint;
//   double _initialRotation = 0.0;
//   double _initialScale = 1.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
//     _playbackTicker = createTicker(_playbackFrame)..start();
//   }
//
//   @override
//   void dispose() {
//     _playbackTicker.dispose();
//     _timelineScrollController.dispose();
//     for (final c in _controllers.values) c.dispose();
//     for (final c in _audioControllers.values) c.dispose();
//     super.dispose();
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PERMISSIONS */
//   /* -------------------------------------------------------------- */
//   Future<bool> _requestPermissions() async {
//     if (Platform.isAndroid) {
//       final androidInfo = await DeviceInfoPlugin().androidInfo;
//       if (androidInfo.version.sdkInt >= 33) {
//         final statuses = await [Permission.videos, Permission.audio].request();
//         return statuses.values.every((s) => s.isGranted);
//       } else {
//         return await Permission.storage.request().isGranted;
//       }
//     } else if (Platform.isIOS) {
//       final statuses = await [Permission.videos, Permission.photos].request();
//       return statuses.values.every((s) => s.isGranted);
//     }
//     return true;
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PLAYBACK LOOP */
//   /* -------------------------------------------------------------- */
//   void _playbackFrame(Duration elapsed) {
//     if (!mounted || !_playing) return;
//     final now = DateTime.now().millisecondsSinceEpoch;
//     final deltaMs = now - _lastFrameTime;
//     _lastFrameTime = now;
//     if (deltaMs <= 0 || deltaMs > 100) return;
//
//     setState(() {
//       _currentPosition += Duration(milliseconds: deltaMs);
//       if (_currentPosition >= _totalDuration) {
//         _currentPosition = _totalDuration;
//         _playing = false;
//         _playbackTicker.stop();
//       }
//     });
//     _updatePlayheadScroll();
//     _updatePreview();
//   }
//
//   void _updatePlayheadScroll() {
//     if (!_timelineScrollController.hasClients) return;
//     final target = (_currentPosition.inMilliseconds / 1000.0 * _pixelsPerSecond) -
//         (MediaQuery.of(context).size.width / 2 - 100);
//     final maxScroll = _timelineScrollController.position.maxScrollExtent;
//     final clamped = target.clamp(0.0, maxScroll);
//     if ((clamped - _timelineScrollController.offset).abs() > 5) {
//       _timelineScrollController.jumpTo(clamped);
//     }
//   }
//
//   void _togglePlay() {
//     setState(() {
//       _playing = !_playing;
//       if (_playing && _currentPosition >= _totalDuration) {
//         _currentPosition = Duration.zero;
//         _resetAllControllers();
//       }
//     });
//     if (_playing) {
//       _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
//       _playbackTicker.start();
//     } else {
//       _playbackTicker.stop();
//     }
//   }
//
//   void _resetAllControllers() {
//     for (final ctrl in _controllers.values) {
//       ctrl.seekTo(Duration.zero);
//       ctrl.pause();
//     }
//     for (final ctrl in _audioControllers.values) {
//       ctrl.seek(Duration.zero);
//       ctrl.pause();
//     }
//     _audioPositions.clear();
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PREVIEW UPDATE */
//   /* -------------------------------------------------------------- */
//   void _updatePreview() {
//     if (!mounted) return;
//     final activeVideo = _findActiveVideo();
//     final activeAudioItems = _findActiveAudio();
//
//     setState(() => _activeItem = activeVideo);
//
//     if (activeVideo != null) {
//       final ctrl = _controllers[activeVideo.id]!;
//       final localTime = _currentPosition - activeVideo.startTime;
//       final sourceTime = activeVideo.trimStart + localTime.multiply(activeVideo.speed);
//
//       if ((ctrl.value.position - sourceTime).inMilliseconds.abs() > 100) {
//         ctrl.seekTo(sourceTime);
//       }
//       ctrl.setPlaybackSpeed(activeVideo.speed);
//       ctrl.setVolume(activeVideo.volume);
//
//       if (_playing && !ctrl.value.isPlaying) ctrl.play();
//       if (!_playing && ctrl.value.isPlaying) ctrl.pause();
//
//       if (_activePreviewController != ctrl) {
//         _activePreviewController?.pause();
//         setState(() => _activePreviewController = ctrl);
//       }
//     } else {
//       _activePreviewController?.pause();
//       if (_activePreviewController != null) {
//         setState(() => _activePreviewController = null);
//       }
//     }
//
//     for (final item in activeAudioItems) {
//       final ctrl = _audioControllers[item.id];
//       if (ctrl == null) continue;
//       final localTime = _currentPosition - item.startTime;
//       final sourceTime = item.trimStart + localTime.multiply(item.speed);
//       final currentPos = _audioPositions[item.id] ?? Duration.zero;
//
//       if ((currentPos - sourceTime).inMilliseconds.abs() > 100) {
//         ctrl.seek(sourceTime);
//       }
//       ctrl.setPlaybackRate(item.speed);
//       ctrl.setVolume(item.volume);
//
//       if (_playing && ctrl.state != PlayerState.playing) {
//         ctrl.resume();
//       }
//     }
//
//     for (final item in _audioItems.where((i) => !activeAudioItems.contains(i))) {
//       _audioControllers[item.id]?.pause();
//     }
//   }
//
//   TimelineItem? _findActiveVideo() {
//     for (final item in _items) {
//       final effectiveDur = item.duration.divide(item.speed);
//       if (_currentPosition >= item.startTime &&
//           _currentPosition < item.startTime + effectiveDur) {
//         return item;
//       }
//     }
//     return null;
//   }
//
//   List<TimelineItem> _findActiveAudio() {
//     final active = <TimelineItem>[];
//     for (final item in _audioItems) {
//       final effectiveDur = item.duration.divide(item.speed);
//       if (_currentPosition >= item.startTime &&
//           _currentPosition < item.startTime + effectiveDur) {
//         active.add(item);
//       }
//     }
//     return active;
//   }
//
//   /* -------------------------------------------------------------- */
//   /* ADD VIDEO */
//   /* -------------------------------------------------------------- */
//   Future<void> _addVideo() async {
//     if (!await _requestPermissions()) {
//       _showError('Permission denied');
//       return;
//     }
//     try {
//       final XFile? file = await _picker.pickVideo(
//         source: ImageSource.gallery,
//         maxDuration: const Duration(minutes: 10),
//       );
//       if (file == null) return;
//       await _addVideoFile(file.path);
//     } catch (e) {
//       _showError('Failed to pick video: $e');
//     }
//   }
//
//   Future<void> _addVideoFile(String filePath) async {
//     _showLoading();
//     try {
//       final info = await FFprobeKit.getMediaInformation(filePath);
//       final media = info.getMediaInformation();
//       if (media == null) throw Exception('Invalid video file');
//
//       final durSec = double.tryParse(media.getDuration() ?? '0') ?? 0.0;
//       final duration = Duration(milliseconds: (durSec * 1000).round());
//       final dir = await getTemporaryDirectory();
//       final thumbs = <String>[];
//
//       for (int i = 0; i < 10; i++) {
//         final ms = (duration.inMilliseconds * i / 9).round();
//         final path = await VideoThumbnail.thumbnailFile(
//           video: filePath,
//           thumbnailPath: dir.path,
//           imageFormat: ImageFormat.PNG,
//           maxWidth: 100,
//           timeMs: ms,
//         );
//         if (path != null) thumbs.add(path);
//       }
//
//       final startTime = _items.isEmpty
//           ? Duration.zero
//           : _items.map((i) => i.startTime + i.duration).reduce((a, b) => a > b ? a : b);
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.video,
//         file: File(filePath),
//         startTime: startTime,
//         duration: duration,
//         originalDuration: duration,
//       );
//       item.thumbnailPaths.addAll(thumbs);
//
//       final ctrl = VideoPlayerController.file(File(filePath));
//       await ctrl.initialize();
//       await ctrl.setLooping(false);
//
//       setState(() {
//         _items.add(item);
//         _selected = item;
//         _controllers[item.id] = ctrl;
//         _updateTotalDuration();
//         _activePreviewController = ctrl;
//       });
//
//       _hideLoading();
//       _showMessage('Video added');
//     } catch (e) {
//       _hideLoading();
//       _showError('Failed to add video: $e');
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* ADD AUDIO */
//   /* -------------------------------------------------------------- */
//   Future<void> _addAudio() async {
//     try {
//       final result = await FilePicker.platform.pickFiles(
//         type: FileType.audio,
//         allowMultiple: false,
//       );
//       if (result == null || result.files.isEmpty) return;
//       final filePath = result.files.first.path;
//       if (filePath == null) {
//         _showError('Invalid file path');
//         return;
//       }
//
//       _showLoading();
//       final info = await FFprobeKit.getMediaInformation(filePath);
//       final media = info.getMediaInformation();
//       final durSec = double.tryParse(media?.getDuration() ?? '0') ?? 0.0;
//       if (durSec <= 0) {
//         _hideLoading();
//         _showError('Invalid audio file');
//         return;
//       }
//
//       final duration = Duration(milliseconds: (durSec * 1000).round());
//       final videoDur = _items.fold(Duration.zero, (sum, i) => sum + i.duration);
//       final itemDur = duration > videoDur && videoDur > Duration.zero ? videoDur : duration;
//
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.audio,
//         file: File(filePath),
//         startTime: Duration.zero,
//         duration: itemDur,
//         originalDuration: duration,
//       );
//
//       item.waveformData = await _generateWaveform(filePath, 100);
//
//       final ctrl = AudioPlayer();
//       await ctrl.setSource(DeviceFileSource(filePath));
//       await ctrl.setVolume(item.volume);
//
//       ctrl.onPositionChanged.listen((pos) {
//         if (mounted) {
//           setState(() => _audioPositions[item.id] = pos);
//         }
//       });
//
//       setState(() {
//         _audioItems.add(item);
//         _selected = item;
//         _audioControllers[item.id] = ctrl;
//         _updateTotalDuration();
//       });
//
//       _hideLoading();
//       _showMessage('Audio added');
//     } catch (e) {
//       _hideLoading();
//       _showError('Failed to add audio: $e');
//     }
//   }
//
//   Future<List<double>> _generateWaveform(String filePath, int samples) async {
//     try {
//       final dir = await getTemporaryDirectory();
//       final outPath = '${dir.path}/waveform_${DateTime.now().millisecondsSinceEpoch}.pcm';
//       final command = '-i "$filePath" -f s16le -ac 1 -ar 44100 "$outPath"';
//       final session = await FFmpegKit.execute(command);
//
//       if (!ReturnCode.isSuccess(await session.getReturnCode())) {
//         return List.filled(samples, 0.5);
//       }
//
//       final file = File(outPath);
//       if (!await file.exists()) return List.filled(samples, 0.5);
//
//       final bytes = await file.readAsBytes();
//       await file.delete();
//
//       if (bytes.length < 2) return List.filled(samples, 0.5);
//
//       // Ensure we have enough bytes for int16 conversion
//       final int16List = Int16List.view(bytes.buffer);
//       if (int16List.isEmpty) return List.filled(samples, 0.5);
//
//       final step = math.max(1, int16List.length ~/ samples);
//       final data = <double>[];
//
//       for (int i = 0; i < samples && i * step < int16List.length; i++) {
//         final sample = int16List[i * step];
//         data.add((sample.abs() / 32768).clamp(0.0, 1.0));
//       }
//
//       // Fill remaining samples if needed
//       while (data.length < samples) {
//         data.add(0.5);
//       }
//
//       return data;
//     } catch (e) {
//       debugPrint('Waveform generation error: $e');
//       return List.filled(samples, 0.5);
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* ADD TEXT / OVERLAY */
//   /* -------------------------------------------------------------- */
//   Future<void> _addText() async {
//     final item = TimelineItem(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       type: TimelineItemType.text,
//       text: "New Text",
//       startTime: _currentPosition,
//       duration: const Duration(seconds: 5),
//       originalDuration: const Duration(seconds: 5),
//       x: 100,
//       y: 200,
//     );
//
//     setState(() {
//       _textItems.add(item);
//       _selected = item;
//       _updateTotalDuration();
//     });
//     _showMessage('Text added');
//   }
//
//   Future<void> _addOverlay() async {
//     if (!await _requestPermissions()) {
//       _showError('Permission denied');
//       return;
//     }
//     try {
//       final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
//       if (file == null) return;
//
//       final duration = const Duration(seconds: 5);
//       final item = TimelineItem(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         type: TimelineItemType.image,
//         file: File(file.path),
//         startTime: _currentPosition,
//         duration: duration,
//         originalDuration: duration,
//         x: 50,
//         y: 100,
//       );
//
//       setState(() {
//         _overlayItems.add(item);
//         _selected = item;
//         _updateTotalDuration();
//       });
//       _showMessage('Overlay added');
//     } catch (e) {
//       _showError('Failed to add overlay: $e');
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* SPLIT / DELETE / DUPLICATE */
//   /* -------------------------------------------------------------- */
//   Future<void> _split() async {
//     if (_selected == null ||
//         (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) {
//       _showError('Select a video or audio clip');
//       return;
//     }
//
//     final item = _selected!;
//     if (_currentPosition < item.startTime ||
//         _currentPosition >= item.startTime + item.duration) {
//       _showError('Move playhead inside the clip');
//       return;
//     }
//
//     final splitTime = _currentPosition - item.startTime;
//     final splitSource = splitTime.multiply(item.speed);
//
//     final first = item.copyWith(
//       duration: splitTime,
//       trimEnd: item.trimStart + splitSource,
//     );
//
//     final secondId = DateTime.now().millisecondsSinceEpoch.toString();
//     final second = item.copyWith(
//       id: secondId,
//       startTime: item.startTime + splitTime,
//       duration: item.duration - splitTime,
//       trimStart: item.trimStart + splitSource,
//     );
//
//     if (item.type == TimelineItemType.video) {
//       final ctrl = VideoPlayerController.file(item.file!);
//       await ctrl.initialize();
//       _controllers[secondId] = ctrl;
//     } else if (item.type == TimelineItemType.audio) {
//       final ctrl = AudioPlayer();
//       await ctrl.setSource(DeviceFileSource(item.file!.path));
//       await ctrl.setVolume(second.volume);
//       ctrl.onPositionChanged.listen((pos) {
//         if (mounted) setState(() => _audioPositions[secondId] = pos);
//       });
//       _audioControllers[secondId] = ctrl;
//     }
//
//     setState(() {
//       if (item.type == TimelineItemType.video) {
//         final idx = _items.indexOf(item);
//         _items[idx] = first;
//         _items.insert(idx + 1, second);
//       } else {
//         final idx = _audioItems.indexOf(item);
//         _audioItems[idx] = first;
//         _audioItems.insert(idx + 1, second);
//       }
//       _selected = first;
//       _updateTotalDuration();
//     });
//     _showMessage('Split');
//   }
//
//   void _delete() {
//     if (_selected == null) return;
//     final id = _selected!.id;
//     final type = _selected!.type;
//
//     if (type == TimelineItemType.video) {
//       _controllers[id]?.dispose();
//       _controllers.remove(id);
//     } else if (type == TimelineItemType.audio) {
//       _audioControllers[id]?.dispose();
//       _audioControllers.remove(id);
//       _audioPositions.remove(id);
//     }
//
//     setState(() {
//       if (type == TimelineItemType.video) {
//         _items.removeWhere((i) => i.id == id);
//       } else if (type == TimelineItemType.audio) {
//         _audioItems.removeWhere((i) => i.id == id);
//       } else if (type == TimelineItemType.image) {
//         _overlayItems.removeWhere((i) => i.id == id);
//       } else if (type == TimelineItemType.text) {
//         _textItems.removeWhere((i) => i.id == id);
//       }
//       _selected = null;
//       _realignVideoStartTimes();
//       _updateTotalDuration();
//     });
//     _showMessage('Deleted');
//   }
//
//   void _realignVideoStartTimes() {
//     Duration current = Duration.zero;
//     for (final item in _items) {
//       item.startTime = current;
//       current += item.duration;
//     }
//   }
//
//   void _duplicate() {
//     if (_selected == null) return;
//     final item = _selected!;
//     final newId = DateTime.now().millisecondsSinceEpoch.toString();
//     final copy = item.copyWith(
//       id: newId,
//       startTime: item.type == TimelineItemType.video
//           ? item.startTime + item.duration
//           : item.startTime,
//     );
//
//     if (item.type == TimelineItemType.video) {
//       final ctrl = VideoPlayerController.file(item.file!);
//       ctrl.initialize();
//       _controllers[newId] = ctrl;
//     } else if (item.type == TimelineItemType.audio) {
//       final ctrl = AudioPlayer();
//       ctrl.setSource(DeviceFileSource(item.file!.path));
//       ctrl.setVolume(copy.volume);
//       ctrl.onPositionChanged.listen((pos) {
//         if (mounted) setState(() => _audioPositions[newId] = pos);
//       });
//       _audioControllers[newId] = ctrl;
//     }
//
//     setState(() {
//       if (item.type == TimelineItemType.video) {
//         final idx = _items.indexOf(item);
//         _items.insert(idx + 1, copy);
//         _realignVideoStartTimes();
//       } else if (item.type == TimelineItemType.audio) {
//         _audioItems.add(copy);
//       } else if (item.type == TimelineItemType.image) {
//         _overlayItems.add(copy);
//       } else if (item.type == TimelineItemType.text) {
//         _textItems.add(copy);
//       }
//       _selected = copy;
//       _updateTotalDuration();
//     });
//     _showMessage('Duplicated');
//   }
//
//   /* -------------------------------------------------------------- */
//   /* TRIM / SPEED / VOLUME */
//   /* -------------------------------------------------------------- */
//   void _showTrimEditor() {
//     if (_selected == null ||
//         (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) {
//       _showError('Select a video or audio clip');
//       return;
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: const Color(0xFF1A1A1A),
//       builder: (ctx) => _TrimEditorSheet(
//         item: _selected!,
//         onApply: (trimStart, trimEnd) {
//           final newDur = trimEnd - trimStart;
//           setState(() {
//             _selected = _selected!.copyWith(
//               trimStart: trimStart,
//               trimEnd: trimEnd,
//               duration: newDur,
//             );
//             if (_selected!.type == TimelineItemType.video) {
//               _realignVideoStartTimes();
//             }
//             _updateTotalDuration();
//           });
//           Navigator.pop(ctx);
//           _showMessage('Trimmed');
//         },
//       ),
//     );
//   }
//
//   void _showSpeedEditor() {
//     if (_selected == null ||
//         (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) return;
//
//     double tempSpeed = _selected!.speed;
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           height: 250,
//           color: const Color(0xFF1A1A1A),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Speed',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Text('${tempSpeed.toStringAsFixed(2)}x',
//                   style: const TextStyle(color: Colors.white, fontSize: 24)),
//               Slider(
//                 value: tempSpeed,
//                 min: 0.25,
//                 max: 4.0,
//                 divisions: 15,
//                 activeColor: const Color(0xFF00C9CC),
//                 onChanged: (v) => setModalState(() => tempSpeed = v),
//               ),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [0.25, 0.5, 1.0, 2.0, 4.0].map((speed) {
//                   return ElevatedButton(
//                     onPressed: () => setModalState(() => tempSpeed = speed),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: tempSpeed == speed
//                           ? const Color(0xFF00C9CC)
//                           : Colors.grey[800],
//                     ),
//                     child: Text('${speed}x'),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _selected!.speed = tempSpeed;
//                     final trimmedDur = _selected!.trimEnd - _selected!.trimStart;
//                     _selected!.duration = trimmedDur.divide(_selected!.speed);
//                     if (_selected!.type == TimelineItemType.video) {
//                       _realignVideoStartTimes();
//                     }
//                     _updateTotalDuration();
//                   });
//                   Navigator.pop(ctx);
//                   _showMessage('Speed: ${tempSpeed.toStringAsFixed(2)}x');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00C9CC),
//                   foregroundColor: Colors.black,
//                 ),
//                 child: const Text('Apply'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showVolumeEditor() {
//     if (_selected == null ||
//         (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) return;
//
//     double tempVolume = _selected!.volume;
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           height: 200,
//           color: const Color(0xFF1A1A1A),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Volume',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 20),
//               Text('${(tempVolume * 100).toInt()}%',
//                   style: const TextStyle(color: Colors.white, fontSize: 24)),
//               Slider(
//                 value: tempVolume,
//                 min: 0.0,
//                 max: 2.0,
//                 divisions: 20,
//                 activeColor: const Color(0xFF00C9CC),
//                 onChanged: (v) => setModalState(() => tempVolume = v),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() => _selected!.volume = tempVolume);
//                   Navigator.pop(ctx);
//                   _showMessage('Volume: ${(tempVolume * 100).toInt()}%');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00C9CC),
//                   foregroundColor: Colors.black,
//                 ),
//                 child: const Text('Apply'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   /* -------------------------------------------------------------- */
//   /* TEXT / EFFECTS / CROP */
//   /* -------------------------------------------------------------- */
//   void _showTextEditor() {
//     if (_selected == null || _selected!.type != TimelineItemType.text) return;
//
//     final controller = TextEditingController(text: _selected!.text);
//     Color tempColor = _selected!.textColor ?? Colors.white;
//     double tempSize = _selected!.fontSize ?? 32;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (ctx) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           height: 400,
//           color: const Color(0xFF1A1A1A),
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               const Text('Edit Text',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: controller,
//                 style: const TextStyle(color: Colors.white),
//                 decoration: const InputDecoration(
//                   hintText: 'Enter text',
//                   hintStyle: TextStyle(color: Colors.white54),
//                   enabledBorder: UnderlineInputBorder(
//                       borderSide: BorderSide(color: Colors.white54)),
//                 ),
//                 onChanged: (v) => setState(() => _selected!.text = v),
//               ),
//               const SizedBox(height: 20),
//               const Text('Color', style: TextStyle(color: Colors.white)),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Colors.white,
//                   Colors.red,
//                   Colors.yellow,
//                   Colors.blue,
//                   Colors.green,
//                   Colors.purple
//                 ]
//                     .map((c) => _colorButton(c, tempColor, (color) =>
//                     setModalState(() => tempColor = color)))
//                     .toList(),
//               ),
//               const SizedBox(height: 20),
//               const Text('Font Size', style: TextStyle(color: Colors.white)),
//               Slider(
//                 value: tempSize,
//                 min: 10,
//                 max: 100,
//                 activeColor: const Color(0xFF00C9CC),
//                 onChanged: (v) => setModalState(() => tempSize = v),
//               ),
//               Text('${tempSize.toInt()}',
//                   style: const TextStyle(color: Colors.white)),
//               const Spacer(),
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _selected!.textColor = tempColor;
//                     _selected!.fontSize = tempSize;
//                     _selected!.text = controller.text;
//                   });
//                   Navigator.pop(ctx);
//                   _showMessage('Text updated');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF00C9CC),
//                   foregroundColor: Colors.black,
//                 ),
//                 child: const Text('Apply'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _colorButton(Color color, Color current, Function(Color) onTap) {
//     final isSelected = color == current;
//     return GestureDetector(
//       onTap: () => onTap(color),
//       child: Container(
//         margin: const EdgeInsets.symmetric(horizontal: 4),
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(
//               color: isSelected ? Colors.white : Colors.transparent, width: 3),
//         ),
//         child: CircleAvatar(backgroundColor: color, radius: 18),
//       ),
//     );
//   }
//
//   void _showEffectEditor() {
//     if (_selected == null || _selected!.type != TimelineItemType.video) return;
//
//     showModalBottomSheet(
//       context: context,
//       builder: (ctx) => Container(
//         height: 300,
//         color: const Color(0xFF1A1A1A),
//         child: ListView(
//           children: [
//             const Padding(
//               padding: EdgeInsets.all(16),
//               child: Text('Effects',
//                   style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold)),
//             ),
//             _effectTile('None', null, ctx),
//             _effectTile('Grayscale', 'grayscale', ctx),
//             _effectTile('Sepia', 'sepia', ctx),
//             _effectTile('Blur', 'blur', ctx),
//             _effectTile('Vintage', 'vintage', ctx),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _effectTile(String name, String? effect, BuildContext ctx) {
//     final isSelected = _selected?.effect == effect;
//     return ListTile(
//       title: Text(name, style: const TextStyle(color: Colors.white)),
//       trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00C9CC)) : null,
//       tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
//       onTap: () {
//         setState(() => _selected!.effect = effect);
//         Navigator.pop(ctx);
//         _showMessage('Effect: $name');
//       },
//     );
//   }
//
//   /* -------------------------------------------------------------- */
//   /* PREVIEW OVERLAYS */
//   /* -------------------------------------------------------------- */
//   List<Widget> _buildTextOverlays() {
//     final overlays = <Widget>[];
//     for (final item in _textItems) {
//       final effectiveDur = item.duration;
//       if (_currentPosition >= item.startTime &&
//           _currentPosition < item.startTime + effectiveDur) {
//         Widget textWidget = Transform.rotate(
//           angle: item.rotation * math.pi / 180,
//           child: Transform.scale(
//             scale: item.scale,
//             child: Text(
//               item.text ?? '',
//               style: TextStyle(
//                 color: item.textColor,
//                 fontSize: item.fontSize,
//                 fontWeight: FontWeight.bold,
//                 shadows: [
//                   Shadow(
//                       offset: const Offset(1, 1),
//                       blurRadius: 3,
//                       color: Colors.black.withOpacity(0.5)),
//                 ],
//               ),
//             ),
//           ),
//         );
//
//         if (item == _selected) {
//           textWidget = GestureDetector(
//             onPanUpdate: (d) {
//               setState(() {
//                 item.x = (item.x ?? 0) + d.delta.dx;
//                 item.y = (item.y ?? 0) + d.delta.dy;
//               });
//             },
//             onScaleStart: (d) {
//               _initialRotation = item.rotation;
//               _initialScale = item.scale;
//             },
//             onScaleUpdate: (d) {
//               setState(() {
//                 item.rotation = _initialRotation + d.rotation * 180 / math.pi;
//                 item.scale = (_initialScale * d.scale).clamp(0.5, 3.0);
//               });
//             },
//             child: Container(
//               decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
//               child: textWidget,
//             ),
//           );
//         }
//
//         overlays.add(Positioned(
//           left: item.x,
//           top: item.y,
//           child: textWidget,
//         ));
//       }
//     }
//     return overlays;
//   }
//
//   List<Widget> _buildOverlayWidgets() {
//     final overlays = <Widget>[];
//     for (final item in _overlayItems) {
//       final effectiveDur = item.duration;
//       if (_currentPosition >= item.startTime &&
//           _currentPosition < item.startTime + effectiveDur) {
//         Widget imageWidget = item.file != null
//             ? Transform.rotate(
//           angle: item.rotation * math.pi / 180,
//           child: Transform.scale(
//             scale: item.scale,
//             child: Image.file(item.file!, width: 200, height: 200, fit: BoxFit.contain),
//           ),
//         )
//             : const SizedBox.shrink();
//
//         if (item == _selected) {
//           imageWidget = GestureDetector(
//             onPanUpdate: (d) {
//               setState(() {
//                 item.x = (item.x ?? 0) + d.delta.dx;
//                 item.y = (item.y ?? 0) + d.delta.dy;
//               });
//             },
//             onScaleStart: (d) {
//               _initialRotation = item.rotation;
//               _initialScale = item.scale;
//             },
//             onScaleUpdate: (d) {
//               setState(() {
//                 item.rotation = _initialRotation + d.rotation * 180 / math.pi;
//                 item.scale = (_initialScale * d.scale).clamp(0.3, 2.0);
//               });
//             },
//             child: Container(
//               decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
//               child: imageWidget,
//             ),
//           );
//         }
//
//         overlays.add(Positioned(
//           left: item.x,
//           top: item.y,
//           child: imageWidget,
//         ));
//       }
//     }
//     return overlays;
//   }
//
//   ColorFilter _getEffectFilter(String? effect) {
//     switch (effect) {
//       case 'grayscale':
//         return const ColorFilter.mode(Colors.grey, BlendMode.saturation);
//       case 'sepia':
//         return const ColorFilter.matrix([
//           0.393, 0.769, 0.189, 0, 0,
//           0.349, 0.686, 0.168, 0, 0,
//           0.272, 0.534, 0.131, 0, 0,
//           0,     0,     0,     1, 0,
//         ]);
//       case 'vintage':
//         return const ColorFilter.matrix([
//           0.6, 0.3, 0.1, 0, 0,
//           0.2, 0.5, 0.3, 0, 0,
//           0.2, 0.2, 0.4, 0, 0,
//           0,   0,   0,   1, 0,
//         ]);
//       default:
//         return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
//     }
//   }
//
//   /* -------------------------------------------------------------- */
//   /* EXPORT */
//   /* -------------------------------------------------------------- */
//   Future<void> _exportVideo() async {
//     if (_items.isEmpty) {
//       _showError('No video to export');
//       return;
//     }
//     _showLoading();
//     try {
//       final dir = await getTemporaryDirectory();
//       final outPath = '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
//       final command = await _generateFFmpegCommand(outPath);
//       final session = await FFmpegKit.execute(command);
//       final rc = await session.getReturnCode();
//       _hideLoading();
//
//       if (ReturnCode.isSuccess(rc)) {
//         _showMessage('Exported: $outPath');
//       } else {
//         final output = await session.getOutput();
//         _showError('Export failed: $output');
//       }
//     } catch (e) {
//       _hideLoading();
//       _showError('Export error: $e');
//     }
//   }
//
//   Future<String> _generateFFmpegCommand(String outPath) async {
//     if (_items.length == 1) {
//       final item = _items.first;
//       final trimStart = item.trimStart.inSeconds;
//       final trimDur = (item.trimEnd - item.trimStart).inSeconds;
//       return '-ss $trimStart -t $trimDur -i "${item.file!.path}" '
//           '-vf "setpts=${1/item.speed}*PTS" '
//           '-af "atempo=${item.speed}" '
//           '-c:v libx264 -preset fast -crf 23 "$outPath"';
//     }
//
//     final inputs = _items.map((i) => '-i "${i.file!.path}"').join(' ');
//     final filter = _items.asMap().entries.map((e) {
//       final i = e.key;
//       final item = e.value;
//       final start = item.trimStart.inSeconds;
//       final dur = (item.trimEnd - item.trimStart).inSeconds;
//       return '[$i:v]trim=start=$start:duration=$dur,setpts=PTS-STARTPTS,speed=${item.speed}[v$i];';
//     }).join('');
//     final concat = _items.asMap().entries.map((e) => '[v${e.key}]').join('');
//
//     return '$inputs -filter_complex "$filter$concat concat=n=${_items.length}:v=1:a=0[outv]" '
//         '-map "[outv]" -c:v libx264 -preset fast -crf 23 "$outPath"';
//   }
//
//   /* -------------------------------------------------------------- */
//   /* HELPERS */
//   /* -------------------------------------------------------------- */
//   void _updateTotalDuration() {
//     final all = [..._items, ..._audioItems, ..._overlayItems, ..._textItems];
//     if (all.isEmpty) {
//       _totalDuration = Duration.zero;
//       return;
//     }
//     _totalDuration = all
//         .map((i) => i.startTime + i.duration)
//         .reduce((a, b) => a > b ? a : b);
//   }
//
//   void _showLoading() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Center(
//           child: CircularProgressIndicator(color: Color(0xFF00C9CC))),
//     );
//   }
//
//   void _hideLoading() {
//     if (Navigator.canPop(context)) Navigator.pop(context);
//   }
//
//   void _showError(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(msg), backgroundColor: Colors.red));
//   }
//
//   void _showMessage(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text(msg), backgroundColor: const Color(0xFF10B981)));
//   }
//
//   String _formatDuration(Duration d) {
//     final min = d.inMinutes.toString().padLeft(2, '0');
//     final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
//     return '$min:$sec';
//   }
//
//   double _getClipWidth(TimelineItem item) {
//     final seconds = item.duration.inMilliseconds / 1000.0;
//     return math.max(seconds * _pixelsPerSecond, 80);
//   }
//
//   /* -------------------------------------------------------------- */
//   /* BUILD UI */
//   /* -------------------------------------------------------------- */
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//             Expanded(child: _buildPreview()),
//             _buildPlaybackControls(),
//             _buildTimeline(),
//             if (_selected != null) _buildEditToolbar(),
//             _buildBottomNav(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTopBar() => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//     color: Colors.black,
//     child: Row(
//       children: [
//         IconButton(
//             icon: const Icon(Icons.close, color: Colors.white, size: 28),
//             onPressed: () {}),
//         const Spacer(),
//         ElevatedButton(
//           onPressed: _exportVideo,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFF00C9CC),
//             foregroundColor: Colors.black,
//             padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
//           ),
//           child: const Text('Export',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
//         ),
//       ],
//     ),
//   );
//
//   Widget _buildPreview() => Container(
//     margin: const EdgeInsets.all(8),
//     child: Center(
//       child: AspectRatio(
//         aspectRatio: 9 / 16,
//         child: Container(
//           decoration: BoxDecoration(
//               color: Colors.black, borderRadius: BorderRadius.circular(8)),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Stack(
//               key: _previewKey,
//               fit: StackFit.expand,
//               children: [
//                 if (_activePreviewController != null &&
//                     _activePreviewController!.value.isInitialized)
//                   ColorFiltered(
//                     colorFilter: _getEffectFilter(_activeItem?.effect),
//                     child: FittedBox(
//                       fit: BoxFit.contain,
//                       child: SizedBox(
//                         width: _activePreviewController!.value.size.width,
//                         height: _activePreviewController!.value.size.height,
//                         child: VideoPlayer(_activePreviewController!),
//                       ),
//                     ),
//                   )
//                 else
//                   Container(
//                     color: const Color(0xFF1A1A1A),
//                     child: const Center(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.video_library,
//                               size: 60, color: Colors.white24),
//                           SizedBox(height: 8),
//                           Text('Add a video to start editing',
//                               style: TextStyle(color: Colors.white54)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ..._buildOverlayWidgets(),
//                 ..._buildTextOverlays(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
//
//   Widget _buildPlaybackControls() => Container(
//     color: Colors.black,
//     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//     child: Row(
//       children: [
//         const Spacer(),
//         IconButton(
//           icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
//               color: Colors.white, size: 32),
//           onPressed: _togglePlay,
//         ),
//         const Spacer(),
//       ],
//     ),
//   );
//
//   Widget _buildTimeline() => Container(
//     height: 300,
//     color: Colors.black,
//     child: Column(
//       children: [
//         Container(
//           height: 30,
//           padding: const EdgeInsets.symmetric(horizontal: 16),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(_formatDuration(_currentPosition),
//                   style: const TextStyle(
//                       color: Color(0xFF00C9CC),
//                       fontSize: 13,
//                       fontWeight: FontWeight.w500)),
//               ...List.generate(5, (i) {
//                 final time = _totalDuration.inSeconds > 0
//                     ? (_totalDuration.inSeconds / 4 * i).round()
//                     : i * 10;
//                 return Text(_formatDuration(Duration(seconds: time)),
//                     style: const TextStyle(
//                         color: Colors.white54, fontSize: 11));
//               }),
//             ],
//           ),
//         ),
//         Expanded(
//           child: Stack(
//             children: [
//               SingleChildScrollView(
//                 controller: _timelineScrollController,
//                 scrollDirection: Axis.horizontal,
//                 child: Padding(
//                   padding: const EdgeInsets.only(left: 100, right: 100),
//                   child: Column(
//                     children: [
//                       Row(children: [
//                         Container(
//                             width: 70,
//                             height: 90,
//                             margin: const EdgeInsets.only(right: 4),
//                             decoration: BoxDecoration(
//                                 color: const Color(0xFF1A1A1A),
//                                 borderRadius: BorderRadius.circular(8)),
//                             child: const Icon(Icons.videocam,
//                                 color: Colors.white54, size: 28)),
//                         ..._items.map((item) => _buildTimelineClip(item)),
//                         _buildAddButton(),
//                       ]),
//                       const SizedBox(height: 8),
//                       Row(children: [
//                         GestureDetector(
//                             onTap: _addAudio,
//                             child: Container(
//                                 width: 148,
//                                 height: 50,
//                                 margin: const EdgeInsets.only(right: 8),
//                                 decoration: BoxDecoration(
//                                     color: const Color(0xFF1A1A1A),
//                                     borderRadius: BorderRadius.circular(8)),
//                                 child: const Row(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.music_note,
//                                           color: Colors.white54, size: 20),
//                                       SizedBox(width: 8),
//                                       Text('Add audio',
//                                           style: TextStyle(
//                                               color: Colors.white54,
//                                               fontSize: 13))
//                                     ]))),
//                         ..._audioItems.map((item) => _buildAudioClip(item)),
//                       ]),
//                       const SizedBox(height: 8),
//                       Row(children: [
//                         GestureDetector(
//                             onTap: _addText,
//                             child: Container(
//                                 width: 148,
//                                 height: 50,
//                                 margin: const EdgeInsets.only(right: 8),
//                                 decoration: BoxDecoration(
//                                     color: const Color(0xFF1A1A1A),
//                                     borderRadius: BorderRadius.circular(8)),
//                                 child: const Row(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.text_fields,
//                                           color: Colors.white54, size: 20),
//                                       SizedBox(width: 8),
//                                       Text('Add text',
//                                           style: TextStyle(
//                                               color: Colors.white54,
//                                               fontSize: 13))
//                                     ]))),
//                         ..._textItems.map((item) => _buildTextClip(item)),
//                       ]),
//                       const SizedBox(height: 8),
//                       Row(children: [
//                         GestureDetector(
//                             onTap: _addOverlay,
//                             child: Container(
//                                 width: 148,
//                                 height: 50,
//                                 margin: const EdgeInsets.only(right: 8),
//                                 decoration: BoxDecoration(
//                                     color: const Color(0xFF1A1A1A),
//                                     borderRadius: BorderRadius.circular(8)),
//                                 child: const Row(
//                                     mainAxisAlignment:
//                                     MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.layers,
//                                           color: Colors.white54, size: 20),
//                                       SizedBox(width: 8),
//                                       Text('Add overlay',
//                                           style: TextStyle(
//                                               color: Colors.white54,
//                                               fontSize: 13))
//                                     ]))),
//                         ..._overlayItems
//                             .map((item) => _buildOverlayClip(item)),
//                       ]),
//                     ],
//                   ),
//                 ),
//               ),
//               if (_totalDuration.inMilliseconds > 0)
//                 Positioned(
//                   left: MediaQuery.of(context).size.width / 2,
//                   top: 0,
//                   bottom: 0,
//                   child: Container(
//                     width: 2,
//                     color: Colors.white,
//                     child: Column(
//                       children: [
//                         Container(
//                             width: 12,
//                             height: 12,
//                             decoration: const BoxDecoration(
//                                 color: Colors.white, shape: BoxShape.circle)),
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
//
//   Widget _buildTimelineClip(TimelineItem item) {
//     final isSelected = item == _selected;
//     final width = _getClipWidth(item);
//     return GestureDetector(
//       onTap: () => setState(() => _selected = item),
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             width: width,
//             height: 90,
//             margin: const EdgeInsets.only(right: 4),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                   color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent,
//                   width: 2),
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: item.thumbnailPaths.isNotEmpty
//                   ? Row(
//                   children: item.thumbnailPaths
//                       .map((p) => Expanded(
//                       child: Image.file(File(p),
//                           fit: BoxFit.cover, height: 90)))
//                       .toList())
//                   : Container(
//                   color: const Color(0xFF2A2A2A),
//                   child: const Center(
//                       child: Icon(Icons.videocam,
//                           color: Colors.white54, size: 32))),
//             ),
//           ),
//           if (item.speed != 1.0)
//             Positioned(
//                 top: 4,
//                 right: 8,
//                 child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//                     decoration: BoxDecoration(
//                         color: const Color(0xFF00C9CC),
//                         borderRadius: BorderRadius.circular(4)),
//                     child: Text('${item.speed.toStringAsFixed(1)}x',
//                         style: const TextStyle(
//                             color: Colors.black,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold)))),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAudioClip(TimelineItem item) {
//     final isSelected = item == _selected;
//     final width = _getClipWidth(item);
//     return GestureDetector(
//       onTap: () => setState(() => _selected = item),
//       onHorizontalDragUpdate: (d) {
//         setState(() {
//           final delta = d.delta.dx / _pixelsPerSecond;
//           item.startTime += Duration(milliseconds: (delta * 1000).round());
//           item.startTime = item.startTime
//               .clamp(Duration.zero, _totalDuration - item.duration);
//         });
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             width: width,
//             height: 50,
//             margin: const EdgeInsets.only(right: 4),
//             decoration: BoxDecoration(
//                 color: const Color(0xFF10B981),
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(
//                     color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent,
//                     width: 2)),
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(6),
//                 child: item.waveformData != null
//                     ? CustomPaint(painter: WaveformPainter(item.waveformData!))
//                     : const Center(
//                     child: Icon(Icons.audiotrack,
//                         color: Colors.white, size: 24))),
//           ),
//           if (isSelected) ...[
//             Positioned(
//                 left: -10,
//                 top: 0,
//                 bottom: 0,
//                 child: GestureDetector(
//                     onHorizontalDragUpdate: (d) =>
//                         _handleTrimDrag(item, d, isLeft: true),
//                     child: Container(
//                         width: 20,
//                         color: Colors.transparent,
//                         child: const Center(
//                             child: Icon(Icons.drag_handle_rounded,
//                                 color: Colors.white, size: 20))))),
//             Positioned(
//                 right: -10,
//                 top: 0,
//                 bottom: 0,
//                 child: GestureDetector(
//                     onHorizontalDragUpdate: (d) =>
//                         _handleTrimDrag(item, d, isLeft: false),
//                     child: Container(
//                         width: 20,
//                         color: Colors.transparent,
//                         child: const Center(
//                             child: Icon(Icons.drag_handle_rounded,
//                                 color: Colors.white, size: 20))))),
//           ],
//         ],
//       ),
//     );
//   }
//
//   void _handleTrimDrag(TimelineItem item, DragUpdateDetails d,
//       {required bool isLeft}) {
//     final minDur = const Duration(milliseconds: 500);
//     final deltaSec = d.delta.dx / _pixelsPerSecond;
//     final deltaDur = Duration(milliseconds: (deltaSec * 1000).round());
//
//     setState(() {
//       if (isLeft) {
//         final newTrimStart =
//         (item.trimStart + deltaDur).clamp(Duration.zero, item.trimEnd - minDur);
//         item.duration = item.trimEnd - newTrimStart;
//         item.trimStart = newTrimStart;
//       } else {
//         final newTrimEnd = (item.trimEnd + deltaDur)
//             .clamp(item.trimStart + minDur, item.originalDuration);
//         item.duration = newTrimEnd - item.trimStart;
//         item.trimEnd = newTrimEnd;
//       }
//       if (item.type == TimelineItemType.video) _realignVideoStartTimes();
//       _updateTotalDuration();
//     });
//   }
//
//   Widget _buildTextClip(TimelineItem item) {
//     final isSelected = item == _selected;
//     final width = _getClipWidth(item);
//     return GestureDetector(
//       onTap: () => setState(() => _selected = item),
//       onHorizontalDragUpdate: (d) {
//         setState(() {
//           final delta = d.delta.dx / _pixelsPerSecond;
//           item.startTime += Duration(milliseconds: (delta * 1000).round());
//           item.startTime = item.startTime.clamp(Duration.zero, _totalDuration);
//         });
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             width: width,
//             height: 50,
//             margin: const EdgeInsets.only(right: 4),
//             decoration: BoxDecoration(
//                 color: const Color(0xFF3B82F6),
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(
//                     color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent,
//                     width: 2)),
//             child: Center(
//                 child: Text(item.text ?? 'Text',
//                     style: const TextStyle(color: Colors.white, fontSize: 12),
//                     overflow: TextOverflow.ellipsis)),
//           ),
//           if (isSelected)
//             Positioned(
//               right: -10,
//               top: 0,
//               bottom: 0,
//               child: GestureDetector(
//                 onHorizontalDragUpdate: (d) {
//                   setState(() {
//                     final delta = d.delta.dx / _pixelsPerSecond;
//                     final newDur = item.duration +
//                         Duration(milliseconds: (delta * 1000).round());
//                     item.duration = newDur.clamp(
//                         const Duration(milliseconds: 500), const Duration(minutes: 1));
//                     _updateTotalDuration();
//                   });
//                 },
//                 child: Container(
//                     width: 20,
//                     color: Colors.transparent,
//                     child: const Center(
//                         child: Icon(Icons.drag_handle_rounded,
//                             color: Colors.white, size: 20))),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildOverlayClip(TimelineItem item) {
//     final isSelected = item == _selected;
//     final width = _getClipWidth(item);
//     return GestureDetector(
//       onTap: () => setState(() => _selected = item),
//       onHorizontalDragUpdate: (d) {
//         setState(() {
//           final delta = d.delta.dx / _pixelsPerSecond;
//           item.startTime += Duration(milliseconds: (delta * 1000).round());
//           item.startTime = item.startTime.clamp(Duration.zero, _totalDuration);
//         });
//       },
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Container(
//             width: width,
//             height: 50,
//             margin: const EdgeInsets.only(right: 4),
//             decoration: BoxDecoration(
//                 color: const Color(0xFFEF4444),
//                 borderRadius: BorderRadius.circular(6),
//                 border: Border.all(
//                     color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent,
//                     width: 2)),
//             child: ClipRRect(
//                 borderRadius: BorderRadius.circular(6),
//                 child: item.file != null
//                     ? Image.file(item.file!, fit: BoxFit.cover)
//                     : const Center(
//                     child: Icon(Icons.image, color: Colors.white, size: 24))),
//           ),
//           if (isSelected)
//             Positioned(
//               right: -10,
//               top: 0,
//               bottom: 0,
//               child: GestureDetector(
//                 onHorizontalDragUpdate: (d) {
//                   setState(() {
//                     final delta = d.delta.dx / _pixelsPerSecond;
//                     final newDur = item.duration +
//                         Duration(milliseconds: (delta * 1000).round());
//                     item.duration = newDur.clamp(
//                         const Duration(milliseconds: 500), _totalDuration);
//                     _updateTotalDuration();
//                   });
//                 },
//                 child: Container(
//                     width: 20,
//                     color: Colors.transparent,
//                     child: const Center(
//                         child: Icon(Icons.drag_handle_rounded,
//                             color: Colors.white, size: 20))),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildAddButton() => GestureDetector(
//     onTap: _addVideo,
//     child: Container(
//       width: 80,
//       height: 90,
//       decoration: BoxDecoration(
//           color: const Color(0xFF1A1A1A),
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.white24)),
//       child: const Icon(Icons.add, color: Colors.white54, size: 32),
//     ),
//   );
//
//   Widget _buildEditToolbar() {
//     if (_selected == null) return const SizedBox.shrink();
//
//     final buttons = <Widget>[
//       IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _delete, tooltip: 'Delete'),
//       IconButton(icon: const Icon(Icons.copy, color: Colors.white), onPressed: _duplicate, tooltip: 'Duplicate'),
//     ];
//
//     if (_selected!.type == TimelineItemType.video || _selected!.type == TimelineItemType.audio) {
//       buttons.insertAll(0, [
//         IconButton(icon: const Icon(Icons.content_cut, color: Colors.white), onPressed: _showTrimEditor, tooltip: 'Trim'),
//         IconButton(icon: const Icon(Icons.call_split, color: Colors.white), onPressed: _split, tooltip: 'Split'),
//         IconButton(icon: const Icon(Icons.speed, color: Colors.white), onPressed: _showSpeedEditor, tooltip: 'Speed'),
//         IconButton(icon: const Icon(Icons.volume_up, color: Colors.white), onPressed: _showVolumeEditor, tooltip: 'Volume'),
//       ]);
//     }
//
//     if (_selected!.type == TimelineItemType.video) {
//       buttons.addAll([
//         IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.white), onPressed: _showEffectEditor, tooltip: 'Effects'),
//       ]);
//     } else if (_selected!.type == TimelineItemType.text) {
//       buttons.insert(0, IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _showTextEditor, tooltip: 'Edit Text'));
//     }
//
//     return Container(
//       height: 60,
//       color: Colors.black87,
//       child: ListView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 8),
//         children: buttons,
//       ),
//     );
//   }
//
//   Widget _buildBottomNav() => Container(
//     height: 70,
//     decoration: const BoxDecoration(
//         color: Colors.black,
//         border: Border(top: BorderSide(color: Colors.white12, width: 0.5))),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         _navTab('Edit', Icons.cut, () => setState(() => _mode = 'Edit')),
//         _navTab('Audio', Icons.music_note, () {
//           setState(() => _mode = 'Audio');
//           _addAudio();
//         }),
//         _navTab('Text', Icons.text_fields, () {
//           setState(() => _mode = 'Text');
//           _addText();
//         }),
//         _navTab('Effects', Icons.auto_awesome, () {
//           setState(() => _mode = 'Effects');
//           if (_selected?.type == TimelineItemType.video) _showEffectEditor();
//         }),
//         _navTab('Overlay', Icons.layers, () {
//           setState(() => _mode = 'Overlay');
//           _addOverlay();
//         }),
//       ],
//     ),
//   );
//
//   Widget _navTab(String label, IconData icon, VoidCallback onTap) {
//     final isActive = _mode == label;
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(vertical: 8),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon,
//                 color: isActive ? const Color(0xFF00C9CC) : Colors.white54,
//                 size: 24),
//             const SizedBox(height: 4),
//             Text(label,
//                 style: TextStyle(
//                     color: isActive ? const Color(0xFF00C9CC) : Colors.white54,
//                     fontSize: 11,
//                     fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// /* ------------------------------------------------------------------ */
// /* WAVEFORM PAINTER */
// /* ------------------------------------------------------------------ */
// class WaveformPainter extends CustomPainter {
//   final List<double> data;
//   WaveformPainter(this.data);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.7)
//       ..strokeWidth = 2
//       ..style = PaintingStyle.stroke;
//
//     final barWidth = size.width / data.length;
//     for (int i = 0; i < data.length; i++) {
//       final barHeight = data[i] * size.height;
//       final x = i * barWidth;
//       final y1 = (size.height - barHeight) / 2;
//       final y2 = y1 + barHeight;
//       canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter old) => false;
// }
//
// /* ------------------------------------------------------------------ */
// /* TRIM EDITOR SHEET */
// /* ------------------------------------------------------------------ */
// class _TrimEditorSheet extends StatefulWidget {
//   final TimelineItem item;
//   final Function(Duration, Duration) onApply;
//   const _TrimEditorSheet({required this.item, required this.onApply});
//
//   @override
//   State<_TrimEditorSheet> createState() => _TrimEditorSheetState();
// }
//
// class _TrimEditorSheetState extends State<_TrimEditorSheet> {
//   late Duration _trimStart;
//   late Duration _trimEnd;
//
//   @override
//   void initState() {
//     super.initState();
//     _trimStart = widget.item.trimStart;
//     _trimEnd = widget.item.trimEnd;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final totalMs = widget.item.originalDuration.inMilliseconds;
//     final width = MediaQuery.of(context).size.width - 100;
//
//     return Container(
//       height: 300,
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: [
//           const Text('Trim Clip',
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold)),
//           const SizedBox(height: 16),
//           Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(_formatSec(_trimStart.inMilliseconds / 1000),
//                     style: const TextStyle(color: Colors.white)),
//                 Text(_formatSec(_trimEnd.inMilliseconds / 1000),
//                     style: const TextStyle(color: Colors.white)),
//               ]),
//           const SizedBox(height: 16),
//           Stack(
//             children: [
//               Container(
//                   height: 60,
//                   decoration: BoxDecoration(
//                       color: Colors.white24,
//                       borderRadius: BorderRadius.circular(8))),
//               Positioned(
//                 left: (_trimStart.inMilliseconds / totalMs) * width,
//                 right: width - (_trimEnd.inMilliseconds / totalMs) * width,
//                 top: 0,
//                 bottom: 0,
//                 child: Container(
//                     decoration: BoxDecoration(
//                         color: const Color(0xFF00C9CC).withOpacity(0.5),
//                         borderRadius: BorderRadius.circular(8))),
//               ),
//               Positioned(
//                 left: (_trimStart.inMilliseconds / totalMs) * width - 20,
//                 top: 0,
//                 bottom: 0,
//                 child: GestureDetector(
//                   onHorizontalDragUpdate: (d) {
//                     final newMs = _trimStart.inMilliseconds +
//                         (d.delta.dx / width * totalMs).round();
//                     setState(() => _trimStart = Duration(
//                         milliseconds: newMs.clamp(
//                             0, _trimEnd.inMilliseconds - 500)));
//                   },
//                   child: Container(
//                       width: 40,
//                       color: Colors.transparent,
//                       child: const Icon(Icons.drag_handle, color: Colors.white)),
//                 ),
//               ),
//               Positioned(
//                 right: width - (_trimEnd.inMilliseconds / totalMs) * width - 20,
//                 top: 0,
//                 bottom: 0,
//                 child: GestureDetector(
//                   onHorizontalDragUpdate: (d) {
//                     final newMs = _trimEnd.inMilliseconds +
//                         (d.delta.dx / width * totalMs).round();
//                     setState(() => _trimEnd = Duration(
//                         milliseconds: newMs.clamp(
//                             _trimStart.inMilliseconds + 500, totalMs)));
//                   },
//                   child: Container(
//                       width: 40,
//                       color: Colors.transparent,
//                       child: const Icon(Icons.drag_handle, color: Colors.white)),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: () {
//               widget.onApply(_trimStart, _trimEnd);
//             },
//             style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF00C9CC),
//                 foregroundColor: Colors.black,
//                 padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
//             child: const Text('Apply Trim'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatSec(double sec) {
//     final m = (sec ~/ 60).toString().padLeft(2, '0');
//     final s = (sec % 60).toStringAsFixed(1).padLeft(4, '0');
//     return '$m:$s';
//   }
// }

import 'dart:io' show File, Platform;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

void main() => runApp(const VideoEditorApp());

class VideoEditorApp extends StatelessWidget {
  const VideoEditorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CapCut Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFF00C9CC),
        useMaterial3: true,
      ),
      home: const VideoEditorScreen(),
    );
  }
}

/* ------------------------------------------------------------------ */
/* MODELS & COMMANDS */
/* ------------------------------------------------------------------ */
enum TimelineItemType { video, audio, image, text }

class TimelineItem {
  final String id;
  final TimelineItemType type;
  final File? file;
  String? text;
  Duration startTime;
  Duration duration;
  Duration originalDuration;
  Duration trimStart;
  Duration trimEnd;
  double speed;
  double volume;
  Color? textColor;
  double? fontSize;
  double? x;
  double? y;
  double rotation;
  double scale;
  String? effect;
  final List<String> thumbnailPaths = [];
  List<double>? waveformData;
  Rect? cropRect;

  TimelineItem({
    required this.id,
    required this.type,
    this.file,
    this.text,
    required this.startTime,
    required this.duration,
    required this.originalDuration,
    Duration? trimStart,
    Duration? trimEnd,
    this.speed = 1.0,
    this.volume = 1.0,
    this.textColor = Colors.white,
    this.fontSize = 32,
    this.x,
    this.y,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.effect,
    this.cropRect,
  })  : trimStart = trimStart ?? Duration.zero,
        trimEnd = trimEnd ?? originalDuration;

  TimelineItem copyWith({
    String? id,
    Duration? startTime,
    Duration? duration,
    Duration? trimStart,
    Duration? trimEnd,
    double? speed,
    double? volume,
    String? text,
    Color? textColor,
    double? fontSize,
    double? x,
    double? y,
    double? rotation,
    double? scale,
    String? effect,
    Rect? cropRect,
  }) {
    return TimelineItem(
      id: id ?? this.id,
      type: type,
      file: file,
      text: text ?? this.text,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      originalDuration: originalDuration,
      trimStart: trimStart ?? this.trimStart,
      trimEnd: trimEnd ?? this.trimEnd,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      x: x ?? this.x,
      y: y ?? this.y,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      effect: effect ?? this.effect,
      cropRect: cropRect ?? this.cropRect,
    )..thumbnailPaths.addAll(thumbnailPaths);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TimelineItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/* ---------- Command pattern for Undo/Redo ---------- */
abstract class Command {
  void execute();
  void undo();
  void redo() => execute();
}

class UndoManager {
  final List<Command> _history = [];
  int _pointer = -1;

  void execute(Command cmd) {
    cmd.execute();
    _history.length = _pointer + 1;
    _history.add(cmd);
    _pointer++;
  }

  void undo() {
    if (_pointer < 0) return;
    _history[_pointer].undo();
    _pointer--;
  }

  void redo() {
    if (_pointer >= _history.length - 1) return;
    _pointer++;
    _history[_pointer].redo();
  }

  bool get canUndo => _pointer >= 0;
  bool get canRedo => _pointer < _history.length - 1;
}

/* ------------------------------------------------------------------ */
/* Duration helpers */
/* ------------------------------------------------------------------ */
extension DurationMath on Duration {
  Duration multiply(double factor) =>
      Duration(milliseconds: (inMilliseconds * factor).round());

  Duration divide(double divisor) => divisor == 0
      ? this
      : Duration(milliseconds: (inMilliseconds / divisor).round());

  Duration clamp(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

/* ------------------------------------------------------------------ */
/* MAIN SCREEN */
/* ------------------------------------------------------------------ */
class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});
  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen>
    with TickerProviderStateMixin {
  // ---------- State ----------
  String _mode = 'Edit';
  final List<TimelineItem> _items = [];
  final List<TimelineItem> _audioItems = [];
  final List<TimelineItem> _overlayItems = [];
  final List<TimelineItem> _textItems = [];
  TimelineItem? _selected;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final Map<String, VideoPlayerController> _controllers = {};
  final Map<String, AudioPlayer> _audioControllers = {};
  final Map<String, Duration> _audioPositions = {};
  VideoPlayerController? _activePreviewController;
  TimelineItem? _activeItem;
  bool _playing = false;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _timelineScrollController = ScrollController();
  final GlobalKey _previewKey = GlobalKey();
  late Ticker _playbackTicker;
  int _lastFrameTime = 0;
  double _pixelsPerSecond = 100.0;
  Offset? _lastFocalPoint;
  double _initialRotation = 0.0;
  double _initialScale = 1.0;

  // ---------- Undo / Redo ----------
  final UndoManager _undoManager = UndoManager();

  // ---------- Init / Dispose ----------
  @override
  void initState() {
    super.initState();
    _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
    _playbackTicker = createTicker(_playbackFrame)..start();
  }

  @override
  void dispose() {
    _playbackTicker.dispose();
    _timelineScrollController.dispose();
    for (final c in _controllers.values) c.dispose();
    for (final c in _audioControllers.values) c.dispose();
    super.dispose();
  }

  /* -------------------------------------------------------------- */
  /* PERMISSIONS */
  /* -------------------------------------------------------------- */
  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final statuses = await [Permission.videos, Permission.audio].request();
        return statuses.values.every((s) => s.isGranted);
      } else {
        return await Permission.storage.request().isGranted;
      }
    } else if (Platform.isIOS) {
      final statuses = await [Permission.videos, Permission.photos].request();
      return statuses.values.every((s) => s.isGranted);
    }
    return true;
  }

  /* -------------------------------------------------------------- */
  /* PLAYBACK LOOP */
  /* -------------------------------------------------------------- */
  void _playbackFrame(Duration elapsed) {
    if (!mounted || !_playing) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final deltaMs = now - _lastFrameTime;
    _lastFrameTime = now;
    if (deltaMs <= 0 || deltaMs > 100) return;
    setState(() {
      _currentPosition += Duration(milliseconds: deltaMs);
      if (_currentPosition >= _totalDuration) {
        _currentPosition = _totalDuration;
        _playing = false;
        _playbackTicker.stop();
      }
    });
    _updatePlayheadScroll();
    _updatePreview();
  }

  /* -------------------------------------------------------------- */
/*  PLAY-HEAD – start at the first clip, not at the screen edge   */
/* -------------------------------------------------------------- */
  void _updatePlayheadScroll() {
    if (!_timelineScrollController.hasClients || _items.isEmpty) return;

    const double leftPadding = 70.0;                     // space for track icons
    final double firstClipStartX = leftPadding;          // first clip starts here
    final double playheadX = firstClipStartX +
        (_currentPosition.inMilliseconds / 1000.0 * _pixelsPerSecond);

    final double target = playheadX - MediaQuery.of(context).size.width / 2;
    final double maxScroll = _timelineScrollController.position.maxScrollExtent;
    final double clamped = target.clamp(0.0, maxScroll);

    if ((clamped - _timelineScrollController.offset).abs() > 5) {
      _timelineScrollController.jumpTo(clamped);
    }
  }

/* -------------------------------------------------------------- */
/*  PLAYBACK ROW – Play → Time → Undo → Redo                     */
/* -------------------------------------------------------------- */
  Widget _buildPlaybackRow() => Container(
    color: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        // Play / Pause
        IconButton(
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white, size: 32),
          onPressed: _togglePlay,
        ),
        const SizedBox(width: 12),

        // Time display
        Expanded(
          child: Text(
            '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),

        // Undo
        IconButton(
          icon: Icon(Icons.undo,
              color: _undoManager.canUndo ? Colors.white : Colors.white38),
          onPressed: _undoManager.canUndo
              ? () => setState(() => _undoManager.undo())
              : null,
        ),

        // Redo
        IconButton(
          icon: Icon(Icons.redo,
              color: _undoManager.canRedo ? Colors.white : Colors.white38),
          onPressed: _undoManager.canRedo
              ? () => setState(() => _undoManager.redo())
              : null,
        ),
      ],
    ),
  );

/* -------------------------------------------------------------- */
/*  TIMELINE – exact CapCut layout                               */
/* -------------------------------------------------------------- */
  Widget _buildTimeline() => Container(
    height: 300,
    color: Colors.black,
    child: Column(
      children: [
        // Ruler + Playhead
        _buildRulerAndPlayhead(),

        // Video track + Add button
        _buildVideoTrack(),

        // Audio track
        _buildAudioTrack(),

        // Caption / Text / Effect tracks
        _buildOverlayTrack('Caption', _textItems, Icons.subtitles),
        _buildOverlayTrack('Text', _textItems, Icons.text_fields),
        _buildOverlayTrack('Effect', _overlayItems, Icons.auto_awesome),
      ],
    ),
  );

/* ---------- Ruler + Playhead ---------- */
  Widget _buildRulerAndPlayhead() {
    const double rulerHeight = 30;
    const double leftPadding = 70.0;   // space for track icons

    return SizedBox(
      height: rulerHeight,
      child: Stack(
        children: [
          // Ruler background
          Container(color: const Color(0xFF1A1A1A)),

          // Time marks
          CustomPaint(
            size: Size(double.infinity, rulerHeight),
            painter: _RulerPainter(
              pixelsPerSecond: _pixelsPerSecond,
              totalDuration: _totalDuration,
              leftPadding: leftPadding,
            ),
          ),

          // Playhead (centered on screen)
          if (_totalDuration.inMilliseconds > 0)
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 1,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                color: const Color(0xFF00C9CC),
              ),
            ),
        ],
      ),
    );
  }

/* ---------- Video Track ---------- */
  Widget _buildVideoTrack() => _buildTrackRow(
    icon: Icons.videocam,
    label: null,
    children: [
      ..._items.map(_buildVideoClip),
      _buildAddVideoButton(),
    ],
  );

/* ---------- Generic Track Row ---------- */
  Widget _buildTrackRow({
    required IconData icon,
    required String? label,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Track icon
          SizedBox(
            width: 70,
            child: Center(
              child: Icon(icon, color: Colors.white54, size: 24),
            ),
          ),
          // Clips
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _timelineScrollController,
              child: Row(children: children),
            ),
          ),
        ],
      ),
    );
  }

/* ----------Video Clip ---------- */
  Widget _buildVideoClip(TimelineItem item) {
    final isSelected = item == _selected;
    final width = _getClipWidth(item);
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      child: Container(
        width: width,
        height: 90,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent,
            width: 2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: item.thumbnailPaths.isNotEmpty
              ? Row(
            children: item.thumbnailPaths
                .map((p) => Expanded(
                child: Image.file(File(p), fit: BoxFit.cover)))
                .toList(),
          )
              : Container(
            color: const Color(0xFF2A2A2A),
            child: const Icon(Icons.videocam, color: Colors.white54),
          ),
        ),
      ),
    );
  }

/* ---------- Add Video Button (glued to last clip) ---------- */
  Widget _buildAddVideoButton() {
    return GestureDetector(
      onTap: _addVideo,
      child: Container(
        width: 80,
        height: 90,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: const Icon(Icons.add, color: Colors.white54, size: 32),
      ),
    );
  }

/* ---------- Audio Track ---------- */
  Widget _buildAudioTrack() => _buildTrackRow(
    icon: Icons.music_note,
    label: 'Add Audio',
    children: [
      ..._audioItems.map((i) => _buildAudioClip(i)),
      _buildAddButton('Add Audio', _addAudio),
    ],
  );

/* ---------- Generic Overlay Track ---------- */
  Widget _buildOverlayTrack(String title, List<TimelineItem> items, IconData icon) =>
      _buildTrackRow(
        icon: icon,
        label: title,
        children: [
          ...items.map((i) => _buildOverlayClip(i, title)),
          _buildAddButton(title, () => _addOverlay()),
        ],
      );

  Widget _buildOverlayClip(TimelineItem item, String type) {
    final width = _getClipWidth(item);
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      child: Container(
        width: width,
        height: 50,
        margin: const EdgeInsets.only(right: 4),
        decoration: BoxDecoration(
          color: type == 'Caption'
              ? const Color(0xFF3B82F6)
              : type == 'Text'
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Text(
            item.text ?? type,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

/* ---------- Generic Add Button (audio / overlay) ---------- */
  Widget _buildAddButton(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 120,
      height: 50,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add, color: Colors.white54, size: 20),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    ),
  );
  void _togglePlay() {
    setState(() {
      _playing = !_playing;
      if (_playing && _currentPosition >= _totalDuration) {
        _currentPosition = Duration.zero;
        _resetAllControllers();
      }
    });
    if (_playing) {
      _lastFrameTime = DateTime.now().millisecondsSinceEpoch;
      _playbackTicker.start();
    } else {
      _playbackTicker.stop();
    }
  }

  void _resetAllControllers() {
    for (final ctrl in _controllers.values) {
      ctrl.seekTo(Duration.zero);
      ctrl.pause();
    }
    for (final ctrl in _audioControllers.values) {
      ctrl.seek(Duration.zero);
      ctrl.pause();
    }
    _audioPositions.clear();
  }

  /* -------------------------------------------------------------- */
  /* PREVIEW UPDATE */
  /* -------------------------------------------------------------- */
  void _updatePreview() {
    if (!mounted) return;
    final activeVideo = _findActiveVideo();
    final activeAudioItems = _findActiveAudio();
    setState(() => _activeItem = activeVideo);
    if (activeVideo != null) {
      final ctrl = _controllers[activeVideo.id]!;
      final localTime = _currentPosition - activeVideo.startTime;
      final sourceTime = activeVideo.trimStart + localTime.multiply(activeVideo.speed);
      if ((ctrl.value.position - sourceTime).inMilliseconds.abs() > 100) {
        ctrl.seekTo(sourceTime);
      }
      ctrl.setPlaybackSpeed(activeVideo.speed);
      ctrl.setVolume(activeVideo.volume);
      if (_playing && !ctrl.value.isPlaying) ctrl.play();
      if (!_playing && ctrl.value.isPlaying) ctrl.pause();
      if (_activePreviewController != ctrl) {
        _activePreviewController?.pause();
        setState(() => _activePreviewController = ctrl);
      }
    } else {
      _activePreviewController?.pause();
      if (_activePreviewController != null) {
        setState(() => _activePreviewController = null);
      }
    }
    for (final item in activeAudioItems) {
      final ctrl = _audioControllers[item.id];
      if (ctrl == null) continue;
      final localTime = _currentPosition - item.startTime;
      final sourceTime = item.trimStart + localTime.multiply(item.speed);
      final currentPos = _audioPositions[item.id] ?? Duration.zero;
      if ((currentPos - sourceTime).inMilliseconds.abs() > 100) {
        ctrl.seek(sourceTime);
      }
      ctrl.setPlaybackRate(item.speed);
      ctrl.setVolume(item.volume);
      if (_playing && ctrl.state != PlayerState.playing) {
        ctrl.resume();
      }
    }
    for (final item in _audioItems.where((i) => !activeAudioItems.contains(i))) {
      _audioControllers[item.id]?.pause();
    }
  }

  TimelineItem? _findActiveVideo() {
    for (final item in _items) {
      final effectiveDur = item.duration.divide(item.speed);
      if (_currentPosition >= item.startTime &&
          _currentPosition < item.startTime + effectiveDur) {
        return item;
      }
    }
    return null;
  }

  List<TimelineItem> _findActiveAudio() {
    final active = <TimelineItem>[];
    for (final item in _audioItems) {
      final effectiveDur = item.duration.divide(item.speed);
      if (_currentPosition >= item.startTime &&
          _currentPosition < item.startTime + effectiveDur) {
        active.add(item);
      }
    }
    return active;
  }

  /* -------------------------------------------------------------- */
  /* ADD VIDEO (with Undo) */
  /* -------------------------------------------------------------- */
  Future<void> _addVideo() async {
    if (!await _requestPermissions()) {
      _showError('Permission denied');
      return;
    }
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      if (file == null) return;
      await _addVideoFile(file.path);
    } catch (e) {
      _showError('Failed to pick video: $e');
    }
  }

  Future<void> _addVideoFile(String filePath) async {
    _showLoading();
    try {
      final info = await FFprobeKit.getMediaInformation(filePath);
      final media = info.getMediaInformation();
      if (media == null) throw Exception('Invalid video file');
      final durSec = double.tryParse(media.getDuration() ?? '0') ?? 0.0;
      final duration = Duration(milliseconds: (durSec * 1000).round());
      final dir = await getTemporaryDirectory();
      final thumbs = <String>[];
      for (int i = 0; i < 10; i++) {
        final ms = (duration.inMilliseconds * i / 9).round();
        final path = await VideoThumbnail.thumbnailFile(
          video: filePath,
          thumbnailPath: dir.path,
          imageFormat: ImageFormat.PNG,
          maxWidth: 100,
          timeMs: ms,
        );
        if (path != null) thumbs.add(path);
      }
      final startTime = _items.isEmpty
          ? Duration.zero
          : _items.map((i) => i.startTime + i.duration).reduce((a, b) => a > b ? a : b);
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.video,
        file: File(filePath),
        startTime: startTime,
        duration: duration,
        originalDuration: duration,
      );
      item.thumbnailPaths.addAll(thumbs);
      final ctrl = VideoPlayerController.file(File(filePath));
      await ctrl.initialize();
      await ctrl.setLooping(false);

      final cmd = _AddVideoCommand(
        item: item,
        ctrl: ctrl,
        items: _items,
        controllers: _controllers,
        onUpdate: () => setState(() {
          _selected = item;
          _updateTotalDuration();
          _activePreviewController = ctrl;
        }),
      );
      _undoManager.execute(cmd);
      _hideLoading();
      _showMessage('Video added');
    } catch (e) {
      _hideLoading();
      _showError('Failed to add video: $e');
    }
  }

  /* -------------------------------------------------------------- */
  /* ADD AUDIO (with Undo) */
  /* -------------------------------------------------------------- */
  Future<void> _addAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) {
        _showError('Invalid file path');
        return;
      }
      _showLoading();
      final info = await FFprobeKit.getMediaInformation(filePath);
      final media = info.getMediaInformation();
      final durSec = double.tryParse(media?.getDuration() ?? '0') ?? 0.0;
      if (durSec <= 0) {
        _hideLoading();
        _showError('Invalid audio file');
        return;
      }
      final duration = Duration(milliseconds: (durSec * 1000).round());
      final videoDur = _items.fold(Duration.zero, (sum, i) => sum + i.duration);
      final itemDur = duration > videoDur && videoDur > Duration.zero ? videoDur : duration;
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.audio,
        file: File(filePath),
        startTime: Duration.zero,
        duration: itemDur,
        originalDuration: duration,
      );
      item.waveformData = await _generateWaveform(filePath, 100);
      final ctrl = AudioPlayer();
      await ctrl.setSource(DeviceFileSource(filePath));
      await ctrl.setVolume(item.volume);
      ctrl.onPositionChanged.listen((pos) {
        if (mounted) {
          setState(() => _audioPositions[item.id] = pos);
        }
      });

      final cmd = _AddAudioCommand(
        item: item,
        ctrl: ctrl,
        items: _audioItems,
        controllers: _audioControllers,
        onUpdate: () => setState(() {
          _selected = item;
          _updateTotalDuration();
        }),
      );
      _undoManager.execute(cmd);
      _hideLoading();
      _showMessage('Audio added');
    } catch (e) {
      _hideLoading();
      _showError('Failed to add audio: $e');
    }
  }

  Future<List<double>> _generateWaveform(String filePath, int samples) async {
    try {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/waveform_${DateTime.now().millisecondsSinceEpoch}.pcm';
      final command = '-i "$filePath" -f s16le -ac 1 -ar 44100 "$outPath"';
      final session = await FFmpegKit.execute(command);
      if (!ReturnCode.isSuccess(await session.getReturnCode())) {
        return List.filled(samples, 0.5);
      }
      final file = File(outPath);
      if (!await file.exists()) return List.filled(samples, 0.5);
      final bytes = await file.readAsBytes();
      await file.delete();
      if (bytes.length < 2) return List.filled(samples, 0.5);
      final int16List = Int16List.view(bytes.buffer);
      if (int16List.isEmpty) return List.filled(samples, 0.5);
      final step = math.max(1, int16List.length ~/ samples);
      final data = <double>[];
      for (int i = 0; i < samples && i * step < int16List.length; i++) {
        final sample = int16List[i * step];
        data.add((sample.abs() / 32768).clamp(0.0, 1.0));
      }
      while (data.length < samples) data.add(0.5);
      return data;
    } catch (e) {
      debugPrint('Waveform error: $e');
      return List.filled(samples, 0.5);
    }
  }

  /* -------------------------------------------------------------- */
  /* ADD TEXT / OVERLAY (with Undo) */
  /* -------------------------------------------------------------- */
  Future<void> _addText() async {
    final item = TimelineItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TimelineItemType.text,
      text: "New Text",
      startTime: _currentPosition,
      duration: const Duration(seconds: 5),
      originalDuration: const Duration(seconds: 5),
      x: 100,
      y: 200,
    );
    final cmd = _AddOverlayCommand(
      item: item,
      list: _textItems,
      onUpdate: () => setState(() {
        _selected = item;
        _updateTotalDuration();
      }),
    );
    _undoManager.execute(cmd);
    _showMessage('Text added');
  }

  Future<void> _addOverlay() async {
    if (!await _requestPermissions()) {
      _showError('Permission denied');
      return;
    }
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      final duration = const Duration(seconds: 5);
      final item = TimelineItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TimelineItemType.image,
        file: File(file.path),
        startTime: _currentPosition,
        duration: duration,
        originalDuration: duration,
        x: 50,
        y: 100,
      );
      final cmd = _AddOverlayCommand(
        item: item,
        list: _overlayItems,
        onUpdate: () => setState(() {
          _selected = item;
          _updateTotalDuration();
        }),
      );
      _undoManager.execute(cmd);
      _showMessage('Overlay added');
    } catch (e) {
      _showError('Failed to add overlay: $e');
    }
  }

  /* -------------------------------------------------------------- */
  /* SPLIT / DELETE / DUPLICATE (with Undo) */
  /* -------------------------------------------------------------- */
  Future<void> _split() async {
    if (_selected == null ||
        (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) {
      _showError('Select a video or audio clip');
      return;
    }
    final item = _selected!;
    if (_currentPosition < item.startTime ||
        _currentPosition >= item.startTime + item.duration) {
      _showError('Move playhead inside the clip');
      return;
    }
    final splitTime = _currentPosition - item.startTime;
    final splitSource = splitTime.multiply(item.speed);
    final first = item.copyWith(
      duration: splitTime,
      trimEnd: item.trimStart + splitSource,
    );
    final secondId = DateTime.now().millisecondsSinceEpoch.toString();
    final second = item.copyWith(
      id: secondId,
      startTime: item.startTime + splitTime,
      duration: item.duration - splitTime,
      trimStart: item.trimStart + splitSource,
    );
    VideoPlayerController? secondVideoCtrl;
    AudioPlayer? secondAudioCtrl;
    if (item.type == TimelineItemType.video) {
      secondVideoCtrl = VideoPlayerController.file(item.file!);
      await secondVideoCtrl.initialize();
      _controllers[secondId] = secondVideoCtrl;
    } else {
      secondAudioCtrl = AudioPlayer();
      await secondAudioCtrl.setSource(DeviceFileSource(item.file!.path));
      await secondAudioCtrl.setVolume(second.volume);
      secondAudioCtrl.onPositionChanged.listen((pos) {
        if (mounted) setState(() => _audioPositions[secondId] = pos);
      });
      _audioControllers[secondId] = secondAudioCtrl;
    }
    final cmd = _SplitCommand(
      original: item,
      first: first,
      second: second,
      secondVideoCtrl: secondVideoCtrl,
      secondAudioCtrl: secondAudioCtrl,
      items: item.type == TimelineItemType.video ? _items : _audioItems,
      controllers: item.type == TimelineItemType.video ? _controllers : _audioControllers,
      onUpdate: () => setState(() {
        _selected = first;
        _updateTotalDuration();
      }),
    );
    _undoManager.execute(cmd);
    _showMessage('Split');
  }

  void _delete() {
    if (_selected == null) return;
    final id = _selected!.id;
    final type = _selected!.type;
    final cmd = _DeleteCommand(
      item: _selected!,
      items: type == TimelineItemType.video
          ? _items
          : type == TimelineItemType.audio
          ? _audioItems
          : type == TimelineItemType.image
          ? _overlayItems
          : _textItems,
      controllers: type == TimelineItemType.video
          ? _controllers
          : type == TimelineItemType.audio
          ? _audioControllers
          : null,
      onUpdate: () => setState(() {
        _selected = null;
        _realignVideoStartTimes();
        _updateTotalDuration();
      }),
    );
    _undoManager.execute(cmd);
    _showMessage('Deleted');
  }

  void _duplicate() {
    if (_selected == null) return;
    final item = _selected!;
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final copy = item.copyWith(
      id: newId,
      startTime: item.type == TimelineItemType.video
          ? item.startTime + item.duration
          : item.startTime,
    );
    VideoPlayerController? newCtrl;
    AudioPlayer? newAudioCtrl;
    if (item.type == TimelineItemType.video) {
      newCtrl = VideoPlayerController.file(item.file!);
      newCtrl.initialize();
      _controllers[newId] = newCtrl;
    } else if (item.type == TimelineItemType.audio) {
      newAudioCtrl = AudioPlayer();
      newAudioCtrl.setSource(DeviceFileSource(item.file!.path));
      newAudioCtrl.setVolume(copy.volume);
      newAudioCtrl.onPositionChanged.listen((pos) {
        if (mounted) setState(() => _audioPositions[newId] = pos);
      });
      _audioControllers[newId] = newAudioCtrl;
    }
    final cmd = _DuplicateCommand(
      original: item,
      copy: copy,
      newCtrl: newCtrl,
      newAudioCtrl: newAudioCtrl,
      items: item.type == TimelineItemType.video
          ? _items
          : item.type == TimelineItemType.audio
          ? _audioItems
          : item.type == TimelineItemType.image
          ? _overlayItems
          : _textItems,
      controllers: item.type == TimelineItemType.video
          ? _controllers
          : item.type == TimelineItemType.audio
          ? _audioControllers
          : null,
      onUpdate: () => setState(() {
        _selected = copy;
        if (item.type == TimelineItemType.video) _realignVideoStartTimes();
        _updateTotalDuration();
      }),
    );
    _undoManager.execute(cmd);
    _showMessage('Duplicated');
  }

  void _realignVideoStartTimes() {
    Duration current = Duration.zero;
    for (final item in _items) {
      item.startTime = current;
      current += item.duration;
    }
  }

  /* -------------------------------------------------------------- */
  /* TRIM / SPEED / VOLUME (with Undo) */
  /* -------------------------------------------------------------- */
  void _showTrimEditor() {
    if (_selected == null ||
        (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) {
      _showError('Select a video or audio clip');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (ctx) => _TrimEditorSheet(
        item: _selected!,
        onApply: (trimStart, trimEnd) {
          final newDur = trimEnd - trimStart;
          final cmd = _TrimCommand(
            item: _selected!,
            oldTrimStart: _selected!.trimStart,
            oldTrimEnd: _selected!.trimEnd,
            newTrimStart: trimStart,
            newTrimEnd: trimEnd,
            newDuration: newDur,
            onUpdate: () => setState(() {
              if (_selected!.type == TimelineItemType.video) _realignVideoStartTimes();
              _updateTotalDuration();
            }),
          );
          _undoManager.execute(cmd);
          Navigator.pop(ctx);
          _showMessage('Trimmed');
        },
      ),
    );
  }

  void _showSpeedEditor() {
    if (_selected == null ||
        (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) return;
    double tempSpeed = _selected!.speed;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 250,
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Speed',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('${tempSpeed.toStringAsFixed(2)}x',
                  style: const TextStyle(color: Colors.white, fontSize: 24)),
              Slider(
                value: tempSpeed,
                min: 0.25,
                max: 4.0,
                divisions: 15,
                activeColor: const Color(0xFF00C9CC),
                onChanged: (v) => setModalState(() => tempSpeed = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [0.25, 0.5, 1.0, 2.0, 4.0].map((speed) {
                  return ElevatedButton(
                    onPressed: () => setModalState(() => tempSpeed = speed),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tempSpeed == speed ? const Color(0xFF00C9CC) : Colors.grey[800],
                    ),
                    child: Text('${speed}x'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final trimmedDur = _selected!.trimEnd - _selected!.trimStart;
                  final newDur = trimmedDur.divide(tempSpeed);
                  final cmd = _SpeedCommand(
                    item: _selected!,
                    oldSpeed: _selected!.speed,
                    newSpeed: tempSpeed,
                    newDuration: newDur,
                    onUpdate: () => setState(() {
                      if (_selected!.type == TimelineItemType.video) _realignVideoStartTimes();
                      _updateTotalDuration();
                    }),
                  );
                  _undoManager.execute(cmd);
                  Navigator.pop(ctx);
                  _showMessage('Speed: ${tempSpeed.toStringAsFixed(2)}x');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9CC),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVolumeEditor() {
    if (_selected == null ||
        (_selected!.type != TimelineItemType.video && _selected!.type != TimelineItemType.audio)) return;
    double tempVolume = _selected!.volume;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 200,
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Volume',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('${(tempVolume * 100).toInt()}%',
                  style: const TextStyle(color: Colors.white, fontSize: 24)),
              Slider(
                value: tempVolume,
                min: 0.0,
                max: 2.0,
                divisions: 20,
                activeColor: const Color(0xFF00C9CC),
                onChanged: (v) => setModalState(() => tempVolume = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final cmd = _VolumeCommand(
                    item: _selected!,
                    oldVolume: _selected!.volume,
                    newVolume: tempVolume,
                    onUpdate: () => setState(() {}),
                  );
                  _undoManager.execute(cmd);
                  Navigator.pop(ctx);
                  _showMessage('Volume: ${(tempVolume * 100).toInt()}%');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9CC),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* -------------------------------------------------------------- */
  /* TEXT / EFFECTS / CROP (with Undo) */
  /* -------------------------------------------------------------- */
  void _showTextEditor() {
    if (_selected == null || _selected!.type != TimelineItemType.text) return;
    final controller = TextEditingController(text: _selected!.text);
    Color tempColor = _selected!.textColor ?? Colors.white;
    double tempSize = _selected!.fontSize ?? 32;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 400,
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Edit Text',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter text',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Color', style: TextStyle(color: Colors.white)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Colors.white,
                  Colors.red,
                  Colors.yellow,
                  Colors.blue,
                  Colors.green,
                  Colors.purple
                ].map((c) => _colorButton(c, tempColor, (color) => setModalState(() => tempColor = color)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('Font Size', style: TextStyle(color: Colors.white)),
              Slider(
                value: tempSize,
                min: 10,
                max: 100,
                activeColor: const Color(0xFF00C9CC),
                onChanged: (v) => setModalState(() => tempSize = v),
              ),
              Text('${tempSize.toInt()}', style: const TextStyle(color: Colors.white)),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  final cmd = _TextEditCommand(
                    item: _selected!,
                    oldText: _selected!.text,
                    oldColor: _selected!.textColor,
                    oldSize: _selected!.fontSize,
                    newText: controller.text,
                    newColor: tempColor,
                    newSize: tempSize,
                    onUpdate: () => setState(() {}),
                  );
                  _undoManager.execute(cmd);
                  Navigator.pop(ctx);
                  _showMessage('Text updated');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C9CC),
                  foregroundColor: Colors.black,
                ),
                child: const Text('Apply'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorButton(Color color, Color current, Function(Color) onTap) {
    final isSelected = color == current;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
        ),
        child: CircleAvatar(backgroundColor: color, radius: 18),
      ),
    );
  }

  void _showEffectEditor() {
    if (_selected == null || _selected!.type != TimelineItemType.video) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: const Color(0xFF1A1A1A),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Effects',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _effectTile('None', null, ctx),
            _effectTile('Grayscale', 'grayscale', ctx),
            _effectTile('Sepia', 'sepia', ctx),
            _effectTile('Blur', 'blur', ctx),
            _effectTile('Vintage', 'vintage', ctx),
          ],
        ),
      ),
    );
  }

  Widget _effectTile(String name, String? effect, BuildContext ctx) {
    final isSelected = _selected?.effect == effect;
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF00C9CC)) : null,
      tileColor: isSelected ? Colors.white.withOpacity(0.1) : null,
      onTap: () {
        final cmd = _EffectCommand(
          item: _selected!,
          oldEffect: _selected!.effect,
          newEffect: effect,
          onUpdate: () => setState(() {}),
        );
        _undoManager.execute(cmd);
        Navigator.pop(ctx);
        _showMessage('Effect: $name');
      },
    );
  }

  /* -------------------------------------------------------------- */
  /* PREVIEW OVERLAYS */
  /* -------------------------------------------------------------- */
  List<Widget> _buildTextOverlays() {
    final List<Widget> overlays = [];
    for (final item in _textItems) {
      final effectiveDur = item.duration;
      if (_currentPosition >= item.startTime && _currentPosition < item.startTime + effectiveDur) {
        Widget textWidget = Transform.rotate(
          angle: item.rotation * math.pi / 180,
          child: Transform.scale(
            scale: item.scale,
            child: Text(
              item.text ?? '',
              style: TextStyle(
                color: item.textColor,
                fontSize: item.fontSize,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(offset: const Offset(1, 1), blurRadius: 3, color: Colors.black.withOpacity(0.5)),
                ],
              ),
            ),
          ),
        );
        if (item == _selected) {
          textWidget = GestureDetector(
            onPanUpdate: (d) {
              final cmd = _MoveOverlayCommand(
                item: item,
                oldX: item.x,
                oldY: item.y,
                newX: (item.x ?? 0) + d.delta.dx,
                newY: (item.y ?? 0) + d.delta.dy,
                onUpdate: () => setState(() {}),
              );
              _undoManager.execute(cmd);
            },
            onScaleStart: (d) {
              _initialRotation = item.rotation;
              _initialScale = item.scale;
            },
            onScaleUpdate: (d) {
              final cmd = _TransformOverlayCommand(
                item: item,
                oldRotation: item.rotation,
                oldScale: item.scale,
                newRotation: _initialRotation + d.rotation * 180 / math.pi,
                newScale: (_initialScale * d.scale).clamp(0.5, 3.0),
                onUpdate: () => setState(() {}),
              );
              _undoManager.execute(cmd);
            },
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
              child: textWidget,
            ),
          );
        }
        overlays.add(Positioned(
          left: item.x,
          top: item.y,
          child: textWidget,
        ));
      }
    }
    return overlays;
  }

  List<Widget> _buildOverlayWidgets() {
    final List<Widget> overlays = [];
    for (final item in _overlayItems) {
      final effectiveDur = item.duration;
      if (_currentPosition >= item.startTime && _currentPosition < item.startTime + effectiveDur) {
        Widget imageWidget = item.file != null
            ? Transform.rotate(
          angle: item.rotation * math.pi / 180,
          child: Transform.scale(
            scale: item.scale,
            child: Image.file(item.file!, width: 200, height: 200, fit: BoxFit.contain),
          ),
        )
            : const SizedBox.shrink();
        if (item == _selected) {
          imageWidget = GestureDetector(
            onPanUpdate: (d) {
              final cmd = _MoveOverlayCommand(
                item: item,
                oldX: item.x,
                oldY: item.y,
                newX: (item.x ?? 0) + d.delta.dx,
                newY: (item.y ?? 0) + d.delta.dy,
                onUpdate: () => setState(() {}),
              );
              _undoManager.execute(cmd);
            },
            onScaleStart: (d) {
              _initialRotation = item.rotation;
              _initialScale = item.scale;
            },
            onScaleUpdate: (d) {
              final cmd = _TransformOverlayCommand(
                item: item,
                oldRotation: item.rotation,
                oldScale: item.scale,
                newRotation: _initialRotation + d.rotation * 180 / math.pi,
                newScale: (_initialScale * d.scale).clamp(0.3, 2.0),
                onUpdate: () => setState(() {}),
              );
              _undoManager.execute(cmd);
            },
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
              child: imageWidget,
            ),
          );
        }
        overlays.add(Positioned(
          left: item.x,
          top: item.y,
          child: imageWidget,
        ));
      }
    }
    return overlays;
  }

  ColorFilter _getEffectFilter(String? effect) {
    switch (effect) {
      case 'grayscale':
        return const ColorFilter.mode(Colors.grey, BlendMode.saturation);
      case 'sepia':
        return const ColorFilter.matrix([
          0.393, 0.769, 0.189, 0, 0,
          0.349, 0.686, 0.168, 0, 0,
          0.272, 0.534, 0.131, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'vintage':
        return const ColorFilter.matrix([
          0.6, 0.3, 0.1, 0, 0,
          0.2, 0.5, 0.3, 0, 0,
          0.2, 0.2, 0.4, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  /* -------------------------------------------------------------- */
  /* EXPORT */
  /* -------------------------------------------------------------- */
  Future<void> _exportVideo() async {
    if (_items.isEmpty) {
      _showError('No video to export');
      return;
    }
    _showLoading();
    try {
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final command = await _generateFFmpegCommand(outPath);
      final session = await FFmpegKit.execute(command);
      final rc = await session.getReturnCode();
      _hideLoading();
      if (ReturnCode.isSuccess(rc)) {
        _showMessage('Exported: $outPath');
      } else {
        final output = await session.getOutput();
        _showError('Export failed: $output');
      }
    } catch (e) {
      _hideLoading();
      _showError('Export error: $e');
    }
  }

  Future<String> _generateFFmpegCommand(String outPath) async {
    if (_items.length == 1) {
      final item = _items.first;
      final trimStart = item.trimStart.inSeconds;
      final trimDur = (item.trimEnd - item.trimStart).inSeconds;
      return '-ss $trimStart -t $trimDur -i "${item.file!.path}" '
          '-vf "setpts=${1 / item.speed}*PTS" '
          '-af "atempo=${item.speed}" '
          '-c:v libx264 -preset fast -crf 23 "$outPath"';
    }
    final inputs = _items.map((i) => '-i "${i.file!.path}"').join(' ');
    final filter = _items.asMap().entries.map((e) {
      final i = e.key;
      final item = e.value;
      final start = item.trimStart.inSeconds;
      final dur = (item.trimEnd - item.trimStart).inSeconds;
      return '[$i:v]trim=start=$start:duration=$dur,setpts=PTS-STARTPTS,speed=${item.speed}[v$i];';
    }).join('');
    final concat = _items.asMap().entries.map((e) => '[v${e.key}]').join('');
    return '$inputs -filter_complex "$filter$concat concat=n=${_items.length}:v=1:a=0[outv]" '
        '-map "[outv]" -c:v libx264 -preset fast -crf 23 "$outPath"';
  }

  /* -------------------------------------------------------------- */
  /* HELPERS */
  /* -------------------------------------------------------------- */
  void _updateTotalDuration() {
    final all = [..._items, ..._audioItems, ..._overlayItems, ..._textItems];
    if (all.isEmpty) {
      _totalDuration = Duration.zero;
      return;
    }
    _totalDuration = all
        .map((i) => i.startTime + i.duration)
        .reduce((a, b) => a > b ? a : b);
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Color(0xFF00C9CC))),
    );
  }

  void _hideLoading() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF10B981)));
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.toString().padLeft(2, '0');
    final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds % 1000 ~/ 100).toString();
    return '$min:$sec.$ms';
  }


  double _getClipWidth(TimelineItem item) {
    final seconds = item.duration.inMilliseconds / 1000.0;
    return math.max(seconds * _pixelsPerSecond, 80);
  }

  /* -------------------------------------------------------------- */
  /* UI BUILD */
  /* -------------------------------------------------------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildPreview()),
            _buildPlaybackRow(),
            _buildTimeline(),
            if (_selected != null) _buildEditToolbar(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ---------- Top Bar ----------

  Widget _buildTopBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    color: Colors.black,
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: _exportVideo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C9CC),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          ),
          child: const Text('Export', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

// ---------- Playback Row with Undo/Redo ----------
  // ---------- Playback Row (Play → Time → Undo → Redo) ----------

  // ---------- Preview ----------
  Widget _buildPreview() => Container(
    margin: const EdgeInsets.all(8),
    child: Center(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Container(
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              key: _previewKey,
              fit: StackFit.expand,
              children: [
                if (_activePreviewController != null && _activePreviewController!.value.isInitialized)
                  ColorFiltered(
                    colorFilter: _getEffectFilter(_activeItem?.effect),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: _activePreviewController!.value.size.width,
                        height: _activePreviewController!.value.size.height,
                        child: VideoPlayer(_activePreviewController!),
                      ),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.video_library, size: 60, color: Colors.white24),
                          SizedBox(height: 8),
                          Text('Add a video to start editing',
                              style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    ),
                  ),
                ..._buildOverlayWidgets(),
                ..._buildTextOverlays(),
              ],
            ),
          ),
        ),
      ),
    ),
  );



  Widget _buildAudioClip(TimelineItem item) {
    final isSelected = item == _selected;
    final width = _getClipWidth(item);
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      onHorizontalDragUpdate: (d) {
        final cmd = _MoveClipCommand(
          item: item,
          oldStart: item.startTime,
          newStart: (item.startTime + Duration(milliseconds: (d.delta.dx / _pixelsPerSecond * 1000).round()))
              .clamp(Duration.zero, _totalDuration - item.duration),
          onUpdate: () => setState(() {}),
        );
        _undoManager.execute(cmd);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: 50,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent, width: 2)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.waveformData != null
                    ? CustomPaint(painter: WaveformPainter(item.waveformData!))
                    : const Center(child: Icon(Icons.audiotrack, color: Colors.white, size: 24))),
          ),
          if (isSelected) ...[
            Positioned(
                left: -10,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _handleTrimDrag(item, d, isLeft: true),
                    child: Container(
                        width: 20,
                        color: Colors.transparent,
                        child: const Center(
                            child: Icon(Icons.drag_handle_rounded, color: Colors.white, size: 20))))),
            Positioned(
                right: -10,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _handleTrimDrag(item, d, isLeft: false),
                    child: Container(
                        width: 20,
                        color: Colors.transparent,
                        child: const Center(
                            child: Icon(Icons.drag_handle_rounded, color: Colors.white, size: 20))))),
          ],
        ],
      ),
    );
  }

  void _handleTrimDrag(TimelineItem item, DragUpdateDetails d, {required bool isLeft}) {
    final minDur = const Duration(milliseconds: 500);
    final deltaSec = d.delta.dx / _pixelsPerSecond;
    final deltaDur = Duration(milliseconds: (deltaSec * 1000).round());
    final cmd = _TrimCommand(
      item: item,
      oldTrimStart: item.trimStart,
      oldTrimEnd: item.trimEnd,
      newTrimStart: isLeft
          ? (item.trimStart + deltaDur).clamp(Duration.zero, item.trimEnd - minDur)
          : item.trimStart,
      newTrimEnd: isLeft
          ? item.trimEnd
          : (item.trimEnd + deltaDur).clamp(item.trimStart + minDur, item.originalDuration),
      newDuration: Duration.zero,
      onUpdate: () => setState(() {
        if (item.type == TimelineItemType.video) _realignVideoStartTimes();
        _updateTotalDuration();
      }),
    );
    _undoManager.execute(cmd);
  }

  Widget _buildTextClip(TimelineItem item) {
    final isSelected = item == _selected;
    final width = _getClipWidth(item);
    return GestureDetector(
      onTap: () => setState(() => _selected = item),
      onHorizontalDragUpdate: (d) {
        final cmd = _MoveClipCommand(
          item: item,
          oldStart: item.startTime,
          newStart: (item.startTime + Duration(milliseconds: (d.delta.dx / _pixelsPerSecond * 1000).round()))
              .clamp(Duration.zero, _totalDuration),
          onUpdate: () => setState(() {}),
        );
        _undoManager.execute(cmd);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: width,
            height: 50,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: isSelected ? const Color(0xFF00C9CC) : Colors.transparent, width: 2)),
            child: Center(
                child: Text(item.text ?? 'Text',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis)),
          ),
          if (isSelected)
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) {
                  final newDur = item.duration +
                      Duration(milliseconds: (d.delta.dx / _pixelsPerSecond * 1000).round());
                  final cmd = _DurationCommand(
                    item: item,
                    oldDuration: item.duration,
                    newDuration: newDur.clamp(const Duration(milliseconds: 500), const Duration(minutes: 1)),
                    onUpdate: () => setState(() => _updateTotalDuration()),
                  );
                  _undoManager.execute(cmd);
                },
                child: Container(
                    width: 20,
                    color: Colors.transparent,
                    child: const Center(
                        child: Icon(Icons.drag_handle_rounded, color: Colors.white, size: 20))),
              ),
            ),
        ],
      ),
    );
  }


  // ---------- Edit Toolbar ----------
  Widget _buildEditToolbar() {
    if (_selected == null) return const SizedBox.shrink();
    final List<Widget> buttons = [
      IconButton(icon: const Icon(Icons.delete, color: Colors.white), onPressed: _delete, tooltip: 'Delete'),
      IconButton(icon: const Icon(Icons.copy, color: Colors.white), onPressed: _duplicate, tooltip: 'Duplicate'),
    ];
    if (_selected!.type == TimelineItemType.video || _selected!.type == TimelineItemType.audio) {
      buttons.insertAll(0, [
        IconButton(icon: const Icon(Icons.content_cut, color: Colors.white), onPressed: _showTrimEditor, tooltip: 'Trim'),
        IconButton(icon: const Icon(Icons.call_split, color: Colors.white), onPressed: _split, tooltip: 'Split'),
        IconButton(icon: const Icon(Icons.speed, color: Colors.white), onPressed: _showSpeedEditor, tooltip: 'Speed'),
        IconButton(icon: const Icon(Icons.volume_up, color: Colors.white), onPressed: _showVolumeEditor, tooltip: 'Volume'),
      ]);
    }
    if (_selected!.type == TimelineItemType.video) {
      buttons.add(IconButton(icon: const Icon(Icons.auto_awesome, color: Colors.white), onPressed: _showEffectEditor, tooltip: 'Effects'));
    } else if (_selected!.type == TimelineItemType.text) {
      buttons.insert(0, IconButton(icon: const Icon(Icons.edit, color: Colors.white), onPressed: _showTextEditor, tooltip: 'Edit Text'));
    }
    return Container(
      height: 60,
      color: Colors.black87,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: buttons,
      ),
    );
  }

  // ---------- Bottom Navigation ----------
  Widget _buildBottomNav() => Container(
    height: 70,
    decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _navTab('Edit', Icons.cut, () => setState(() => _mode = 'Edit')),
        _navTab('Audio', Icons.music_note, () {
          setState(() => _mode = 'Audio');
          _addAudio();
        }),
        _navTab('Caption', Icons.subtitles, () {
          setState(() => _mode = 'Caption');
          _addText();
        }),
        _navTab('Text', Icons.text_fields, () {
          setState(() => _mode = 'Text');
          _addText();
        }),
        _navTab('Effect', Icons.auto_awesome, () {
          setState(() => _mode = 'Effect');
          if (_selected?.type == TimelineItemType.video) _showEffectEditor();
        }),
        _navTab('AI', Icons.smart_toy, () => setState(() => _mode = 'AI')),
      ],
    ),
  );

  Widget _navTab(String label, IconData icon, VoidCallback onTap) {
    final isActive = _mode == label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? const Color(0xFF00C9CC) : Colors.white54,
                size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: isActive ? const Color(0xFF00C9CC) : Colors.white54,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* WAVEFORM PAINTER */
/* ------------------------------------------------------------------ */
class WaveformPainter extends CustomPainter {
  final List<double> data;
  WaveformPainter(this.data);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final barWidth = size.width / data.length;
    for (int i = 0; i < data.length; i++) {
      final barHeight = data[i] * size.height;
      final x = i * barWidth;
      final y1 = (size.height - barHeight) / 2;
      final y2 = y1 + barHeight;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/* ------------------------------------------------------------------ */
/* TRIM EDITOR SHEET (completed) */
/* ------------------------------------------------------------------ */
class _TrimEditorSheet extends StatefulWidget {
  final TimelineItem item;
  final Function(Duration, Duration) onApply;
  const _TrimEditorSheet({required this.item, required this.onApply});
  @override
  State<_TrimEditorSheet> createState() => _TrimEditorSheetState();
}

class _TrimEditorSheetState extends State<_TrimEditorSheet> {
  late Duration _trimStart;
  late Duration _trimEnd;

  @override
  void initState() {
    super.initState();
    _trimStart = widget.item.trimStart;
    _trimEnd = widget.item.trimEnd;
  }

  String _formatSec(double sec) {
    final minutes = (sec ~/ 60).toString().padLeft(2, '0');
    final seconds = (sec % 60).toStringAsFixed(1).padLeft(4, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final totalMs = widget.item.originalDuration.inMilliseconds.toDouble();
    final width = MediaQuery.of(context).size.width - 100;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Trim Clip',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatSec(_trimStart.inMilliseconds / 1000),
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                _formatSec(_trimEnd.inMilliseconds / 1000),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              // Background track
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),

              // Trimmed selection overlay
              Positioned(
                left: (_trimStart.inMilliseconds / totalMs) * width,
                right: width - (_trimEnd.inMilliseconds / totalMs) * width,
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C9CC).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Left trim handle
              Positioned(
                left: (_trimStart.inMilliseconds / totalMs) * width - 20,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    final newMs = _trimStart.inMilliseconds +
                        (d.delta.dx / width * totalMs).round();
                    setState(() {
                      _trimStart = Duration(
                        milliseconds: newMs.clamp(0, _trimEnd.inMilliseconds - 500),
                      );
                    });
                  },
                  child: Container(
                    width: 40,
                    color: Colors.transparent,
                    child: const Icon(Icons.drag_handle, color: Colors.white),
                  ),
                ),
              ),

              // Right trim handle
              Positioned(
                right: width - (_trimEnd.inMilliseconds / totalMs) * width - 20,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    final newMs = _trimEnd.inMilliseconds +
                        (d.delta.dx / width * totalMs).round();
                    setState(() {
                      _trimEnd = Duration(
                        milliseconds: newMs.clamp(_trimStart.inMilliseconds + 500, widget.item.originalDuration.inMilliseconds),
                      );
                    });
                  },
                  child: Container(
                    width: 40,
                    color: Colors.transparent,
                    child: const Icon(Icons.drag_handle, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Done button
          ElevatedButton(
            onPressed: () {
              widget.item.trimStart = _trimStart;
              widget.item.trimEnd = _trimEnd;
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

/* ------------------------------------------------------------------ */
/* COMMAND IMPLEMENTATIONS (Undo/Redo)                               */
/* ------------------------------------------------------------------ */

/* ---------- Add Video ---------- */
class _AddVideoCommand extends Command {
  final TimelineItem item;
  final VideoPlayerController ctrl;
  final List<TimelineItem> items;
  final Map<String, VideoPlayerController> controllers;
  final VoidCallback onUpdate;

  _AddVideoCommand({
    required this.item,
    required this.ctrl,
    required this.items,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  void execute() {
    items.add(item);
    controllers[item.id] = ctrl;
    onUpdate();
  }

  @override
  void undo() {
    items.remove(item);
    controllers.remove(item.id);
    ctrl.dispose();
    onUpdate();
  }
}

/* ---------- Add Audio ---------- */
class _AddAudioCommand extends Command {
  final TimelineItem item;
  final AudioPlayer ctrl;
  final List<TimelineItem> items;
  final Map<String, AudioPlayer> controllers;
  final VoidCallback onUpdate;

  _AddAudioCommand({
    required this.item,
    required this.ctrl,
    required this.items,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  void execute() {
    items.add(item);
    controllers[item.id] = ctrl;
    onUpdate();
  }

  @override
  void undo() {
    items.remove(item);
    controllers.remove(item.id);
    ctrl.dispose();
    onUpdate();
  }
}

/* ---------- Add Overlay (image / text) ---------- */
class _AddOverlayCommand extends Command {
  final TimelineItem item;
  final List<TimelineItem> list;
  final VoidCallback onUpdate;

  _AddOverlayCommand({
    required this.item,
    required this.list,
    required this.onUpdate,
  });

  @override
  void execute() {
    list.add(item);
    onUpdate();
  }

  @override
  void undo() {
    list.remove(item);
    onUpdate();
  }
}

/* ---------- Delete ---------- */
class _DeleteCommand extends Command {
  final TimelineItem item;
  final List<TimelineItem> items;
  final Map<String, dynamic>? controllers;
  final VoidCallback onUpdate;
  VideoPlayerController? _videoCtrl;
  AudioPlayer? _audioCtrl;

  _DeleteCommand({
    required this.item,
    required this.items,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  void execute() {
    if (item.type == TimelineItemType.video) {
      _videoCtrl = controllers![item.id] as VideoPlayerController?;
      controllers!.remove(item.id);
    } else if (item.type == TimelineItemType.audio) {
      _audioCtrl = controllers![item.id] as AudioPlayer?;
      controllers!.remove(item.id);
    }
    items.remove(item);
    onUpdate();
  }

  @override
  void undo() {
    items.insert(0, item);
    if (item.type == TimelineItemType.video && _videoCtrl != null) {
      controllers![item.id] = _videoCtrl!;
    } else if (item.type == TimelineItemType.audio && _audioCtrl != null) {
      controllers![item.id] = _audioCtrl!;
    }
    onUpdate();
  }
}

/* ---------- Split ---------- */
class _SplitCommand extends Command {
  final TimelineItem original;
  final TimelineItem first;
  final TimelineItem second;
  final VideoPlayerController? secondVideoCtrl;
  final AudioPlayer? secondAudioCtrl;
  final List<TimelineItem> items;
  final Map<String, dynamic> controllers;
  final VoidCallback onUpdate;

  _SplitCommand({
    required this.original,
    required this.first,
    required this.second,
    required this.secondVideoCtrl,
    required this.secondAudioCtrl,
    required this.items,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  void execute() {
    final idx = items.indexOf(original);
    items
      ..[idx] = first
      ..insert(idx + 1, second);
    if (secondVideoCtrl != null) controllers[second.id] = secondVideoCtrl!;
    if (secondAudioCtrl != null) controllers[second.id] = secondAudioCtrl!;
    onUpdate();
  }

  @override
  void undo() {
    items
      ..remove(first)
      ..remove(second);
    items.insert(items.indexOf(first), original);
    controllers.remove(second.id);
    secondVideoCtrl?.dispose();
    secondAudioCtrl?.dispose();
    onUpdate();
  }
}

/* ---------- Duplicate ---------- */
class _DuplicateCommand extends Command {
  final TimelineItem original;
  final TimelineItem copy;
  final VideoPlayerController? newCtrl;
  final AudioPlayer? newAudioCtrl;
  final List<TimelineItem> items;
  final Map<String, dynamic>? controllers;
  final VoidCallback onUpdate;

  _DuplicateCommand({
    required this.original,
    required this.copy,
    required this.newCtrl,
    required this.newAudioCtrl,
    required this.items,
    required this.controllers,
    required this.onUpdate,
  });

  @override
  void execute() {
    final idx = items.indexOf(original);
    items.insert(idx + 1, copy);
    if (newCtrl != null) controllers![copy.id] = newCtrl!;
    if (newAudioCtrl != null) controllers![copy.id] = newAudioCtrl!;
    onUpdate();
  }

  @override
  void undo() {
    items.remove(copy);
    controllers?.remove(copy.id);
    newCtrl?.dispose();
    newAudioCtrl?.dispose();
    onUpdate();
  }
}

/* ---------- Trim ---------- */
class _TrimCommand extends Command {
  final TimelineItem item;
  final Duration oldTrimStart;
  final Duration oldTrimEnd;
  final Duration newTrimStart;
  final Duration newTrimEnd;
  final Duration newDuration;
  final VoidCallback onUpdate;

  _TrimCommand({
    required this.item,
    required this.oldTrimStart,
    required this.oldTrimEnd,
    required this.newTrimStart,
    required this.newTrimEnd,
    required this.newDuration,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.trimStart = newTrimStart;
    item.trimEnd   = newTrimEnd;
    if (newDuration > Duration.zero) item.duration = newDuration;
    onUpdate();
  }

  @override
  void undo() {
    item.trimStart = oldTrimStart;
    item.trimEnd   = oldTrimEnd;
    onUpdate();
  }
}

/* ---------- Speed ---------- */
class _SpeedCommand extends Command {
  final TimelineItem item;
  final double oldSpeed;
  final double newSpeed;
  final Duration newDuration;
  final VoidCallback onUpdate;

  _SpeedCommand({
    required this.item,
    required this.oldSpeed,
    required this.newSpeed,
    required this.newDuration,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.speed = newSpeed;
    if (newDuration > Duration.zero) item.duration = newDuration;
    onUpdate();
  }

  @override
  void undo() {
    item.speed = oldSpeed;
    onUpdate();
  }
}

/* ---------- Volume ---------- */
class _VolumeCommand extends Command {
  final TimelineItem item;
  final double oldVolume;
  final double newVolume;
  final VoidCallback onUpdate;

  _VolumeCommand({
    required this.item,
    required this.oldVolume,
    required this.newVolume,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.volume = newVolume;
    onUpdate();
  }

  @override
  void undo() {
    item.volume = oldVolume;
    onUpdate();
  }
}

/* ---------- Move Clip (timeline drag) ---------- */
class _MoveClipCommand extends Command {
  final TimelineItem item;
  final Duration oldStart;
  final Duration newStart;
  final VoidCallback onUpdate;

  _MoveClipCommand({
    required this.item,
    required this.oldStart,
    required this.newStart,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.startTime = newStart;
    onUpdate();
  }

  @override
  void undo() {
    item.startTime = oldStart;
    onUpdate();
  }
}

/* ---------- Move Overlay (position drag) ---------- */
class _MoveOverlayCommand extends Command {
  final TimelineItem item;
  final double? oldX;
  final double? oldY;
  final double? newX;
  final double? newY;
  final VoidCallback onUpdate;

  _MoveOverlayCommand({
    required this.item,
    required this.oldX,
    required this.oldY,
    required this.newX,
    required this.newY,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.x = newX;
    item.y = newY;
    onUpdate();
  }

  @override
  void undo() {
    item.x = oldX;
    item.y = oldY;
    onUpdate();
  }
}

/* ---------- Transform Overlay (scale/rotate) ---------- */
class _TransformOverlayCommand extends Command {
  final TimelineItem item;
  final double oldRotation;
  final double oldScale;
  final double newRotation;
  final double newScale;
  final VoidCallback onUpdate;

  _TransformOverlayCommand({
    required this.item,
    required this.oldRotation,
    required this.oldScale,
    required this.newRotation,
    required this.newScale,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.rotation = newRotation;
    item.scale    = newScale;
    onUpdate();
  }

  @override
  void undo() {
    item.rotation = oldRotation;
    item.scale    = oldScale;
    onUpdate();
  }
}

/* ---------- Change Duration (text/overlay length) ---------- */
class _DurationCommand extends Command {
  final TimelineItem item;
  final Duration oldDuration;
  final Duration newDuration;
  final VoidCallback onUpdate;

  _DurationCommand({
    required this.item,
    required this.oldDuration,
    required this.newDuration,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.duration = newDuration;
    onUpdate();
  }

  @override
  void undo() {
    item.duration = oldDuration;
    onUpdate();
  }
}

/* ---------- Edit Text (content, color, size) ---------- */
class _TextEditCommand extends Command {
  final TimelineItem item;
  final String? oldText;
  final Color? oldColor;
  final double? oldSize;
  final String? newText;
  final Color? newColor;
  final double? newSize;
  final VoidCallback onUpdate;

  _TextEditCommand({
    required this.item,
    required this.oldText,
    required this.oldColor,
    required this.oldSize,
    required this.newText,
    required this.newColor,
    required this.newSize,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.text      = newText;
    item.textColor = newColor;
    item.fontSize  = newSize;
    onUpdate();
  }

  @override
  void undo() {
    item.text      = oldText;
    item.textColor = oldColor;
    item.fontSize  = oldSize;
    onUpdate();
  }
}

/* ---------- Apply Effect ---------- */
class _EffectCommand extends Command {
  final TimelineItem item;
  final String? oldEffect;
  final String? newEffect;
  final VoidCallback onUpdate;

  _EffectCommand({
    required this.item,
    required this.oldEffect,
    required this.newEffect,
    required this.onUpdate,
  });

  @override
  void execute() {
    item.effect = newEffect;
    onUpdate();
  }

  @override
  void undo() {
    item.effect = oldEffect;
    onUpdate();
  }
}

class _RulerPainter extends CustomPainter {
  final double pixelsPerSecond;
  final Duration totalDuration;
  final double leftPadding;

  _RulerPainter({
    required this.pixelsPerSecond,
    required this.totalDuration,
    required this.leftPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final step = 2.0; // every 2 seconds

    for (double sec = 0; sec <= totalSeconds; sec += step) {
      final x = leftPadding + sec * pixelsPerSecond;
      if (x < leftPadding || x > size.width) continue;

      // line
      canvas.drawLine(Offset(x, size.height - 8), Offset(x, size.height), paint);

      // label
      final label = _formatRuler(sec);
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white54, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 4));
    }
  }

  String _formatRuler(double sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
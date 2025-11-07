import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:undo/undo.dart';
import 'package:video_player/video_player.dart';

import 'clip_model.dart';
import 'draggable_timeline.dart';
import 'editor_controller.dart';
import 'new.dart';

class VideoEditorScreens extends StatelessWidget {
  final ctrl = Get.put(EditorControllers());
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  VideoEditorScreens({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _previewWithOverlays()),
            _timelineSection(),
            _bottomToolbar(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── TOP BAR ───────────────────────
  Widget _topBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A), width: .5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Export button
          Obx(
            () =>
                ctrl.exporting.value
                    ? const SizedBox(
                      width: 80,
                      height: 32,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                    : SizedBox(
                      width: 80,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        onPressed: () async {
                          final out = await ctrl.exportProject();
                          if (out != null)
                            Get.snackbar('Export', 'Saved to $out');
                        },
                        child: const Text(
                          'Export',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── PREVIEW WITH OVERLAYS ───────────────────────
  Widget _previewWithOverlays() {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  // ---- video player (non‑Obx, just listens to the controller) ----
                  if (ctrl.player != null)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: ctrl.player!,
                      builder: (_, value, __) {
                        if (!value.isInitialized) {
                          return const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                          );
                        }
                        return VideoPlayer(ctrl.player!);
                      },
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),

                  // ---- text overlays (Obx reads only currentMs & selectedIndex) ----
                  Obx(() {
                    final idx = ctrl.selectedIndex.value;
                    if (idx < 0 || idx >= ctrl.clips.length)
                      return const SizedBox();
                    final clip = ctrl.clips[idx];
                    final pos = ctrl.currentMs.value - clip.startMs;
                    return _buildTextOverlays(pos, clip, w, h);
                  }),

                  // ---- sticker overlays (Obx reads only currentMs & selectedIndex) ----
                  Obx(() {
                    final idx = ctrl.selectedIndex.value;
                    if (idx < 0 || idx >= ctrl.clips.length)
                      return const SizedBox();
                    final clip = ctrl.clips[idx];
                    final pos = ctrl.currentMs.value - clip.startMs;
                    return _buildStickerOverlays(pos, clip, w, h);
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextOverlays(double pos, ClipModel clip, double w, double h) {
    return Stack(
      children:
          clip.textOverlays
              .where(
                (ov) => pos >= ov.startMs && pos <= ov.startMs + ov.durationMs,
              )
              .map(
                (ov) => Positioned(
                  left: ov.x * w - 100,
                  top: ov.y * h - 50,
                  child: Text(
                    ov.text,
                    style: TextStyle(
                      color: Color(ov.color),
                      fontSize: ov.fontSize,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(blurRadius: 4, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildStickerOverlays(double pos, ClipModel clip, double w, double h) {
    return Stack(
      children:
          clip.stickerOverlays
              .where(
                (st) => pos >= st.startMs && pos <= st.startMs + st.durationMs,
              )
              .map(
                (st) => Positioned(
                  left: st.x * w - 50 * st.scale,
                  top: st.y * h - 50 * st.scale,
                  child: Transform.rotate(
                    angle: st.rotation,
                    child: GestureDetector(
                      onScaleUpdate: (d) {
                        st.scale = (st.scale * d.scale).clamp(0.5, 3.0);
                        st.rotation += d.rotation;
                        ctrl.clips.refresh(); // minimal refresh
                      },
                      onPanUpdate: (d) {
                        st.x += d.delta.dx / w;
                        st.y += d.delta.dy / h;
                        st.x = st.x.clamp(0.0, 1.0);
                        st.y = st.y.clamp(0.0, 1.0);
                        ctrl.clips.refresh();
                      },
                      child: Container(
                        width: 100 * st.scale,
                        height: 100 * st.scale,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(st.assetPath),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  // ─────────────────────── TIMELINE SECTION ───────────────────────
  Widget _timelineSection() {
    return Container(
      height: 180,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          Expanded(child: _clipsTimelineWithPlayhead()),
          const Divider(height: 1, thickness: .5, color: Color(0xFF2A2A2A)),
          _playbackControls(),
        ],
      ),
    );
  }

  // ───── PLAYBACK CONTROLS (time‑code + slider + play + undo + redo) ─────
  Widget _playbackControls() {
    final ctrl = Get.find<EditorControllers>();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Time code
            SizedBox(
              width: 50,
              child: Obx(
                () => Text(
                  _format(ctrl.currentMs.value / 1000),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),

            // Slider
            SizedBox(
              width: 180, // you can tune this if needed
              child: Obx(() {
                if (ctrl.clips.isEmpty) {
                  return const Slider(value: 0, max: 1, onChanged: null);
                }

                final total =
                    ctrl.clips.fold<double>(
                      0,
                      (p, c) => p + (c.endMs - c.startMs),
                    ) /
                    1000;

                final value =
                    (ctrl.currentMs.value / 1000).clamp(0.0, total).toDouble();

                return Slider(
                  value: value,
                  max: total,
                  activeColor: Colors.purple,
                  inactiveColor: const Color(0xFF2A2A2A),
                  onChanged: (v) => ctrl.seekToMs(v * 1000),
                );
              }),
            ),

            // Play / Pause
            Obx(
              () => IconButton(
                icon: Icon(
                  ctrl.isPlaying.value ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: ctrl.togglePlayPause,
              ),
            ),

            // Undo
            IconButton(
              icon: Icon(
                Icons.undo,
                color: ctrl.canUndo ? Colors.white : Colors.white38,
              ),
              onPressed: ctrl.canUndo ? ctrl.undo : null,
            ),

            // Redo
            IconButton(
              icon: Icon(
                Icons.redo,
                color: ctrl.canRedo ? Colors.white : Colors.white38,
              ),
              onPressed: ctrl.canRedo ? ctrl.redo : null,
            ),
          ],
        ),
      ),
    );
  }

  // ───── CLIPS TIMELINE + PLAYHEAD ─────
  Widget _clipsTimelineWithPlayhead() {
    return Obx(() {
      if (ctrl.clips.isEmpty) {
        return Center(
          child: GestureDetector(
            onTap: ctrl.pickVideo,
            child: const Icon(Icons.add, color: Colors.white, size: 40),
          ),
        );
      }

      final totalDuration = ctrl.clips.fold<double>(
        0,
        (p, c) => p + (c.endMs - c.startMs),
      );

      if (totalDuration == 0) return const SizedBox();

      return LayoutBuilder(
        builder: (context, constraints) {
          final playheadPos = (ctrl.currentMs.value / totalDuration).clamp(
            0.0,
            1.0,
          );
          final left = playheadPos * constraints.maxWidth - 12;

          return Stack(
            children: [
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                itemCount: ctrl.clips.length + 1,
                itemBuilder: (_, i) {
                  if (i == ctrl.clips.length) {
                    return GestureDetector(
                      onTap: ctrl.pickVideo,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    );
                  }
                  final clip = ctrl.clips[i];
                  final isSel = ctrl.selectedIndex.value == i;
                  final width = (clip.endMs - clip.startMs) / 1000 * 30;
                  return GestureDetector(
                    onTap: () {
                      ctrl.selectedIndex.value = i;
                      ctrl.loadSelectedToPlayer();
                    },
                    child: Container(
                      width: width.clamp(60, 300),
                      height: 56,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isSel ? Colors.purple : const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              isSel ? Colors.purple : const Color(0xFF3A3A3A),
                          width: isSel ? 2 : .5,
                        ),
                      ),
                      child:
                          clip.thumbs.isNotEmpty
                              ? Image.file(
                                File(clip.thumbs[clip.thumbs.length ~/ 2]),
                                fit: BoxFit.cover,
                              )
                              : const Center(
                                child: Icon(
                                  Icons.videocam,
                                  color: Colors.white70,
                                ),
                              ),
                    ),
                  );
                },
              ),
              // playhead line
              Positioned(
                left: left.clamp(0, constraints.maxWidth - 2),
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  color: Colors.purple,
                  child: const Align(
                    alignment: Alignment.topCenter,
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.purple,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  // ─────────────────────── BOTTOM TOOLBAR ───────────────────────
  Widget _bottomToolbar() {
    final tabs = [
      {'icon': Icons.content_cut, 'label': 'Edit', 'page': _editTab()},
      {'icon': Icons.volume_up, 'label': 'Audio', 'page': _audioTab()},
      {'icon': Icons.closed_caption, 'label': 'Caption', 'page': _captionTab()},
      {'icon': Icons.text_fields, 'label': 'Text', 'page': _textTab()},
      {'icon': Icons.auto_awesome, 'label': 'Effect', 'page': _effectTab()},
      {'icon': Icons.emoji_objects, 'label': 'Stickers', 'page': _stickerTab()},
    ];

    return Container(
      height: 200,
      color: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // tab bar
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    tabs.asMap().entries.map((e) {
                      final i = e.key;
                      final t = e.value;
                      final sel = ctrl.selectedToolTab.value == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => ctrl.selectedToolTab.value = i,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                t['icon'] as IconData,
                                color:
                                    sel
                                        ? Colors.purple
                                        : const Color(0xFF606060),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['label'] as String,
                                style: TextStyle(
                                  color:
                                      sel
                                          ? Colors.purple
                                          : const Color(0xFF606060),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),
          // tab page
          Expanded(
            child: Obx(
              () => tabs[ctrl.selectedToolTab.value]['page'] as Widget,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── TOOL TABS (unchanged) ───────────────────────
  // (Edit, Audio, Caption, Text, Effect, Stickers – keep the original code)
  // ... (the rest of the file is exactly the same as in the previous answer)

  // ───── Helper to record undo/redo ─────
  VoidCallback _wrap(VoidCallback fn) {
    return () {
      final idx = ctrl.selectedIndex.value;
      if (idx < 0) return;
      final before = ctrl.clips[idx].copy();
      fn();
      final after = ctrl.clips[idx];
      ctrl.addChange(
        Change<ClipModel>(
          before,
          () {
            ctrl.clips[idx] = after;
            ctrl.clips.refresh();
            ctrl.loadSelectedToPlayer();
          },
          (old) {
            ctrl.clips[idx] = old;
            ctrl.clips.refresh();
            ctrl.loadSelectedToPlayer();
          },
        ),
      );
    };
  }

  // ───── Time formatter ─────
  String _format(double secs) {
    final m = (secs / 60).floor().toString().padLeft(2, '0');
    final s = (secs % 60).floor().toString().padLeft(2, '0');
    final ms = ((secs % 1) * 10).floor();
    return '$m:$s.$ms';
  }

  // ───── The rest of the modal / dialog helpers stay exactly the same ─────
  // (volume, speed, trim, transition, voice‑over, auto‑caption, etc.)
  // ... (copy‑paste the original implementations – they are unchanged)

  // ───── Edit Tab (grid of tools) ─────
  Widget _editTab() {
    final tools = [
      {
        'icon': Icons.content_cut,
        'label': 'Split',
        'onTap': _wrap(ctrl.splitClip),
      },
      {'icon': Icons.crop, 'label': 'Trim', 'onTap': _showTrimModal},
      {'icon': Icons.delete, 'label': 'Delete', 'onTap': _wrap(_deleteClip)},
      {'icon': Icons.speed, 'label': 'Speed', 'onTap': _showSpeedModal},
      {'icon': Icons.volume_up, 'label': 'Volume', 'onTap': _showVolumeModal},
      {
        'icon': Icons.flip,
        'label': 'Flip',
        'onTap': _wrap(ctrl.toggleFlipHorizontal),
      },
      {'icon': Icons.copy, 'label': 'Copy', 'onTap': _wrap(_duplicateClip)},
      {'icon': Icons.crop_free, 'label': 'Crop', 'onTap': _showCropModal},
      {
        'icon': Icons.rotate_right,
        'label': 'Rotate',
        'onTap': _wrap(() => ctrl.rotateClip(90)),
      },
      {
        'icon': Icons.swap_horiz,
        'label': 'Transition',
        'onTap': _showTransitionModal,
      },
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 1,
      ),
      itemCount: tools.length,
      itemBuilder:
          (_, i) => GestureDetector(
            onTap: tools[i]['onTap'] as VoidCallback,
            child: Column(
              children: [
                Icon(tools[i]['icon'] as IconData, color: Colors.white),
                Text(
                  tools[i]['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
    );
  }

  // ───── The rest of the file (modals, dialogs, audio tab, caption tab, …) ─────
  // (copy the original implementations – they are unchanged)
  // ... (same as in the previous answer)

  // ───── Delete / Duplicate helpers ─────
  void _deleteClip() {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    final removed = ctrl.clips.removeAt(idx);
    ctrl.addChange(
      Change<ClipModel?>(
        null,
        () {
          ctrl.clips.removeAt(idx);
          ctrl.selectedIndex.value = -1;
        },
        (_) {
          ctrl.clips.insert(idx, removed);
          ctrl.selectedIndex.value = idx;
          ctrl.loadSelectedToPlayer();
        },
      ),
    );
    ctrl.selectedIndex.value = -1;
  }

  void _duplicateClip() {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    final copy = ctrl.clips[idx].copy();
    ctrl.clips.insert(idx + 1, copy);
    ctrl.addChange(
      Change<ClipModel?>(
        null,
        () => ctrl.clips.insert(idx + 1, copy),
        (_) => ctrl.clips.removeAt(idx + 1),
      ),
    );
  }

  // ───── Modals (trim, speed, volume, transition, crop) ─────
  void _showTrimModal() {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    final clip = ctrl.clips[idx];
    Get.bottomSheet(
      Container(
        height: 260,
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text(
              'Trim',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DraggableTimeline(
              videoFile: File(clip.path),
              durationMs: clip.originalDurationMs,
              startMs: clip.startMs,
              endMs: clip.endMs,
              onStartChanged: (v) {
                final before = clip.copyWith(startMs: clip.startMs);
                ctrl.setTrimStart(v);
                ctrl.addChange(
                  Change<ClipModel>(
                    before,
                    () => ctrl.setTrimStart(v),
                    (old) => ctrl.setTrimStart(old.startMs),
                  ),
                );
              },
              onEndChanged: (v) {
                final before = clip.copyWith(endMs: clip.endMs);
                ctrl.setTrimEnd(v);
                ctrl.addChange(
                  Change<ClipModel>(
                    before,
                    () => ctrl.setTrimEnd(v),
                    (old) => ctrl.setTrimEnd(old.endMs),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeedModal() {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    double speed = ctrl.clips[idx].speed;
    Get.bottomSheet(
      Container(
        height: 200,
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Speed',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              value: speed,
              min: 0.25,
              max: 4,
              divisions: 15,
              label: '${speed}x',
              activeColor: Colors.purple,
              onChanged: (v) {
                speed = v;
                ctrl.setSpeed(v);
              },
            ),
            Text('${speed}x', style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showVolumeModal() {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    double vol = ctrl.clips[idx].volume;
    Get.bottomSheet(
      Container(
        height: 200,
        color: const Color(0xFF1A1A1A),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Volume',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Slider(
              value: vol,
              min: 0,
              max: 2,
              divisions: 20,
              label: '${(vol * 100).toInt()}%',
              activeColor: Colors.purple,
              onChanged: (v) {
                vol = v;
                ctrl.setVolume(v);
              },
            ),
            Text(
              '${(vol * 100).toInt()}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransitionModal() {
    final transitions = ['Fade', 'Slide', 'Zoom', 'Wipe'];
    Get.bottomSheet(
      Container(
        height: 300,
        color: const Color(0xFF1A1A1A),
        child: ListView.builder(
          itemCount: transitions.length,
          itemBuilder:
              (_, i) => ListTile(
                title: Text(
                  transitions[i],
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  ctrl.setTransition(transitions[i].toLowerCase(), 0.5);
                  Get.back();
                },
              ),
        ),
      ),
    );
  }

  void _showCropModal() {
    Get.bottomSheet(
      Container(
        height: 200,
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: Text(
            'Crop tool coming soon',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ───── Voice‑over ─────
  Future<void> _startVoiceover() async {
    if (await Permission.microphone.request().isGranted) {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.openRecorder();
      await _recorder.startRecorder(toFile: path);
      Get.dialog(
        AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Recording…',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: _stopVoiceover,
              child: const Text('Stop', style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }
  }

  Future<void> _stopVoiceover() async {
    final path = await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    if (path != null) {
      ctrl.voiceoverPath = path;
      Get.back();
      Get.snackbar('Voice‑over', 'Saved');
    }
  }

  // ───── Auto caption (demo) ─────
  void _autoCaption() {
    Get.dialog(
      const AlertDialog(
        backgroundColor: Color(0xFF1A1A1A),
        title: Text('Auto Caption', style: TextStyle(color: Colors.white)),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.purple),
            SizedBox(width: 16),
            Text('Analyzing…', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      Get.back();
      final ov =
          TextOverlay(text: 'Hello, this is auto caption!')
            ..startMs = 1000
            ..durationMs = 3000
            ..fontSize = 28
            ..color = 0xFFFFFFFF;
      ctrl.addTextOverlay(ov);
      Get.snackbar('Caption', 'Generated');
    });
  }

  // ───── Add text dialog ─────
  void _showAddTextDialog() {
    final txtCtrl = TextEditingController();
    double fontSize = 32;
    Color color = Colors.white;

    showDialog(
      context: Get.context!,
      builder:
          (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Add Text',
              style: TextStyle(color: Colors.white),
            ),
            content: StatefulBuilder(
              builder:
                  (_, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: txtCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter text',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'Size: ',
                            style: TextStyle(color: Colors.white),
                          ),
                          Slider(
                            min: 10,
                            max: 80,
                            value: fontSize,
                            onChanged: (v) => setState(() => fontSize = v),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Color: ',
                            style: TextStyle(color: Colors.white),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final c = await showDialog<Color>(
                                context: dialogCtx,
                                builder:
                                    (_) => AlertDialog(
                                      title: const Text('Pick Color'),
                                      content: BlockPicker(
                                        pickerColor: color,
                                        onColorChanged:
                                            (c) => Navigator.pop(dialogCtx, c),
                                      ),
                                    ),
                              );
                              if (c != null) setState(() => color = c);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (txtCtrl.text.isEmpty) return;
                  final idx = ctrl.selectedIndex.value;
                  if (idx < 0) return;
                  final ov =
                      TextOverlay(text: txtCtrl.text)
                        ..fontSize = fontSize
                        ..color = color.value
                        ..startMs = ctrl.currentMs.value
                        ..durationMs = 5000;
                  ctrl.addTextOverlay(ov);
                  Get.back();
                  Get.snackbar('Text', 'Added');
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // ───── TTS dialog ─────
  void _showTTSDialog() {
    final txtCtrl = TextEditingController();
    showDialog(
      context: Get.context!,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text(
              'Text to Speech',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: txtCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter text',
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Get.back();
                  await ctrl.generateAndSaveTTS(txtCtrl.text);
                },
                child: const Text('Generate'),
              ),
            ],
          ),
    );
  }

  // ───── Audio Tab ─────
  Widget _audioTab() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _toolBtn(
          'Music',
          Colors.purple,
          Icons.music_note,
          ctrl.pickBackgroundMusic,
        ),
        _toolBtn('Voice over', Colors.purple, Icons.mic, _startVoiceover),
        _toolBtn('Denoise', Colors.purple, Icons.volume_down, ctrl.denoiseClip),
        _toolBtn(
          'Text to speech',
          Colors.purple,
          Icons.record_voice_over,
          _showTTSDialog,
        ),
      ],
    );
  }

  // ───── Caption Tab ─────
  Widget _captionTab() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _captionBtn('Add text', Icons.add, _showAddTextDialog),
          _captionBtn('Auto caption', Icons.subtitles_outlined, _autoCaption),
          _captionBtn(
            'Text to speech',
            Icons.record_voice_over_outlined,
            _showTTSDialog,
          ),
        ],
      ),
    );
  }

  // ───── Text / Effect / Sticker Tabs (unchanged) ─────
  Widget _textTab() {
    final styles = ['Default', 'Bold', 'Neon', 'Writer', 'Glitch', '3D'];
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: styles.length,
      itemBuilder:
          (_, i) => GestureDetector(
            onTap: () => _applyTextStyle(styles[i]),
            child: Column(
              children: [
                const Text(
                  'Aa',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                Text(
                  styles[i],
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
    );
  }

  Widget _effectTab() {
    final effects = ['None', 'B&W', 'Sepia', 'Vintage', 'Glitch', 'Blur'];
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
      ),
      itemCount: effects.length,
      itemBuilder:
          (_, i) => GestureDetector(
            onTap: () => ctrl.setFilter(effects[i]),
            child: Column(
              children: [
                const Icon(Icons.filter, color: Colors.white),
                Text(
                  effects[i],
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
    );
  }

  Widget _stickerTab() {
    final categories = ['Recents', 'Favorite', 'GIF', 'Trending', 'Birthday'];
    return Column(
      children: [
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search shapes',
            prefixIcon: Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Color(0xFF1A1A1A),
            border: OutlineInputBorder(borderSide: BorderSide.none),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children:
                categories
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Chip(
                          label: Text(c, style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: 12,
            itemBuilder:
                (_, i) => GestureDetector(
                  onTap: () => _addSticker(i),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'Animation',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
          ),
        ),
      ],
    );
  }

  Widget _toolBtn(String label, Color col, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: col),
          Text(label, style: TextStyle(color: col, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _captionBtn(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  void _applyTextStyle(String style) => Get.snackbar('Style', '$style applied');

  void _addSticker(int i) {
    final idx = ctrl.selectedIndex.value;
    if (idx < 0) return;
    final st =
        StickerOverlay(assetPath: 'assets/sticker$i.png')
          ..startMs = ctrl.currentMs.value
          ..durationMs = 5000
          ..x = 0.5
          ..y = 0.5;
    ctrl.addStickerOverlay(st);
  }
}

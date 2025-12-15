import 'package:flutter/material.dart';
import 'dart:math' as math;


// ==================== PLAYBACK CONTROLS ====================
class PlaybackControls extends StatelessWidget {
  final bool isPlaying;
  final Duration playheadPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onUndo;
  final VoidCallback onRedo;

  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.playheadPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onUndo,
    required this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF000000),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onPlayPause,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            '${_formatTime(playheadPosition)} / ${_formatTime(totalDuration)}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('ON', style: TextStyle(fontSize: 10, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onUndo,
                child: const Icon(Icons.undo, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onRedo,
                child: const Icon(Icons.redo, size: 20, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000.0;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toStringAsFixed(2).padLeft(5, '0')}';
  }
}



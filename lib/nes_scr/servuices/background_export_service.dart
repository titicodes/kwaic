// ========================================
// PRODUCTION ENHANCEMENT 2: BACKGROUND EXPORT
// ========================================

import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../model/timeline_item.dart';

class BackgroundExportService {
  static Future<String?> exportVideoInBackground({
    required List<TimelineItem> clips,
    required List<TimelineItem> audioItems,
    required List<TimelineItem> textItems,
    required List<TimelineItem> overlayItems,
    required String resolution,
    required int bitrate,
    required bool addWatermark,
    Function(double)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final outputPath = '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Build FFmpeg command
      String command = await _buildFFmpegCommand(
        clips: clips,
        audioItems: audioItems,
        textItems: textItems,
        overlayItems: overlayItems,
        resolution: resolution,
        bitrate: bitrate,
        outputPath: outputPath,
        addWatermark: addWatermark,
      );

      debugPrint('🎬 Starting background export...');
      debugPrint('Command: $command');

      // Execute FFmpeg with progress tracking
      final session = await FFmpegKit.executeAsync(
        command,
            (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            debugPrint('✅ Export completed successfully');
          } else {
            debugPrint('❌ Export failed with code: $returnCode');
          }
        },
            (log) {
          // Parse progress from FFmpeg logs
          final message = log.getMessage();
          if (message.contains('time=')) {
            final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+)').firstMatch(message);
            if (timeMatch != null) {
              final hours = int.parse(timeMatch.group(1)!);
              final minutes = int.parse(timeMatch.group(2)!);
              final seconds = int.parse(timeMatch.group(3)!);
              final totalSeconds = hours * 3600 + minutes * 60 + seconds;

              // Calculate progress (rough estimate)
              final totalDuration = _calculateTotalDuration(clips);
              final progress = (totalSeconds / totalDuration).clamp(0.0, 1.0);
              onProgress?.call(progress);
            }
          }
        },
            (statistics) {
          // Handle statistics if needed
        },
      );

      return outputPath;
    } catch (e) {
      debugPrint('❌ Background export error: $e');
      return null;
    }
  }

  static Future<String> _buildFFmpegCommand({
    required List<TimelineItem> clips,
    required List<TimelineItem> audioItems,
    required List<TimelineItem> textItems,
    required List<TimelineItem> overlayItems,
    required String resolution,
    required int bitrate,
    required String outputPath,
    required bool addWatermark,
  }) async {
    final inputs = <String>[];
    final filters = <String>[];
    int inputIndex = 0;

    // Add video inputs
    for (final clip in clips) {
      inputs.add('-i "${clip.file!.path}"');

      // Apply effects (speed, crop, etc.)
      String filterChain = '[$inputIndex:v]';

      // Speed
      if (clip.speed != 1.0) {
        filterChain += 'setpts=${1 / clip.speed}*PTS,';
      }

      // Crop
      if (clip.cropLeft > 0 || clip.cropTop > 0 || clip.cropRight > 0 || clip.cropBottom > 0) {
        filterChain += 'crop=iw*${1 - clip.cropLeft - clip.cropRight}:ih*${1 - clip.cropTop - clip.cropBottom}:iw*${clip.cropLeft}:ih*${clip.cropTop},';
      }

      // Scale to resolution
      final resolutionMap = {'720p': '1280:720', '1080p': '1920:1080', '4K': '3840:2160'};
      filterChain += 'scale=${resolutionMap[resolution] ?? "1920:1080"}';

      filters.add('$filterChain[v$inputIndex]');
      inputIndex++;
    }

    // Add audio inputs
    for (final audio in audioItems) {
      inputs.add('-i "${audio.file!.path}"');

      String audioFilter = '[$inputIndex:a]';
      if (audio.volume != 1.0) {
        audioFilter += 'volume=${audio.volume}';
      }
      audioFilter += '[a$inputIndex]';

      filters.add(audioFilter);
      inputIndex++;
    }

    // Concatenate videos
    String concatFilter = '';
    if (clips.length > 1) {
      concatFilter = clips.asMap().entries.map((e) => '[v${e.key}]').join('') +
          'concat=n=${clips.length}:v=1:a=0[outv];';
    } else {
      concatFilter = '[v0][outv];';
    }

    // Mix audio tracks
    String audioMix = '';
    if (audioItems.isNotEmpty) {
      audioMix = audioItems.asMap().entries.map((e) => '[a${clips.length + e.key}]').join('') +
          'amix=inputs=${audioItems.length}:duration=longest[outa]';
    }

    // Add watermark if needed
    String watermarkFilter = '';
    if (addWatermark) {
      // Assume watermark.png exists in assets
      watermarkFilter = '[outv]drawtext=text=\'Made with VideoEditor\':' +
          'fontsize=24:fontcolor=white@0.5:x=(w-text_w-10):y=(h-text_h-10)[outvw];';
    }

    // Combine all filters
    final filterComplex = filters.join(';') + ';' + concatFilter + audioMix + watermarkFilter;

    // Build final command
    String command = inputs.join(' ') + ' -filter_complex "$filterComplex" ';

    if (addWatermark) {
      command += '-map "[outvw]" ';
    } else {
      command += '-map "[outv]" ';
    }

    if (audioItems.isNotEmpty) {
      command += '-map "[outa]" ';
    }

    command += '-c:v libx264 -preset medium -crf 23 -b:v ${bitrate}k ';
    command += '-c:a aac -b:a 192k ';
    command += '-y "$outputPath"';

    return command;
  }

  static double _calculateTotalDuration(List<TimelineItem> clips) {
    if (clips.isEmpty) return 0;
    return clips.map((c) => c.duration.inSeconds.toDouble()).reduce((a, b) => a + b);
  }
}
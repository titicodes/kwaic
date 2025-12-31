import 'dart:io';


import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';

import '../model/timeline_item.dart';

class VideoExporter {
  static Future<File> export({
    required List<TimelineItem> videoClips,
    required List<TimelineItem> audioClips,
    required List<TimelineItem> textClips,
    required String outputPath,
  }) async {
    if (videoClips.isEmpty) {
      throw Exception('No video clips to export');
    }

    final List<String> inputs = [];
    final List<String> filters = [];

    // ---------- INPUT VIDEOS ----------
    for (final clip in videoClips) {
      inputs.add('-i "${clip.file!.path}"');
    }

    // ---------- BASE VIDEO CONCAT ----------
    final videoInputs =
        List.generate(videoClips.length, (i) => '[$i:v]').join();

    filters.add('$videoInputs concat=n=${videoClips.length}:v=1:a=0 [basev]');

    // ---------- TEXT FILTERS ----------
    String lastVideo = 'basev';
    int textIndex = 0;

    for (final text in textClips) {
      final start = text.startTime.inMilliseconds / 1000;
      final end = (text.startTime + text.duration).inMilliseconds / 1000;

      final fontSize = (40 * (text.scale ?? 1.0)).round();
      final color =
          '#${text.textColor?.value.toRadixString(16).substring(2) ?? 'ffffff'}';

      final baseX = text.x?.round() ?? 100;
      final baseY = text.y?.round() ?? 200;
      final anim = text.animation ?? 'none';

      String xExpr = '$baseX';
      String yExpr = '$baseY';
      String alphaExpr = '1';
      String sizeExpr = '$fontSize';

      // 🎬 ANIMATIONS
      if (anim == 'fade') {
        alphaExpr =
            'if(lt(t,$start+0.3),(t-$start)/0.3, if(gt(t,$end-0.3),($end-t)/0.3,1))';
      }

      if (anim == 'slide_up') {
        yExpr = '$baseY + (1 - min(1,(t-$start)/0.3)) * 80';
      }

      if (anim == 'slide_left') {
        xExpr = '$baseX + (1 - min(1,(t-$start)/0.3)) * 120';
      }

      if (anim == 'pop') {
        sizeExpr = '$fontSize * (1 + 0.3 * exp(-6*(t-$start)))';
      }

      final drawText = '''
[$lastVideo]drawtext=
text='${_escape(text.text ?? '')}':
fontsize=$sizeExpr:
fontcolor=$color:
alpha=$alphaExpr:
x=$xExpr:
y=$yExpr:
enable='between(t,$start,$end)'
[text$textIndex]
'''.replaceAll('\n', '');

      filters.add(drawText);
      lastVideo = 'text$textIndex';
      textIndex++;
    }

    // ---------- AUDIO ----------
    final audioInputs = <String>[];
    for (final audio in audioClips) {
      audioInputs.add('-i "${audio.file!.path}"');
    }

    final audioFilter =
        audioClips.isNotEmpty
            ? '${List.generate(audioClips.length, (i) => '[${videoClips.length + i}:a]').join()}'
                'amix=inputs=${audioClips.length}:dropout_transition=0[aout]'
            : 'anullsrc[aout]';

    filters.add(audioFilter);

    // ---------- FINAL COMMAND ----------
    final command = '''
${inputs.join(' ')}
${audioInputs.join(' ')}
-filter_complex "${filters.join(';')}"
-map "[$lastVideo]"
-map "[aout]"
-c:v libx264
-preset veryfast
-crf 18
-pix_fmt yuv420p
"$outputPath"
'''.replaceAll('\n', ' ');

    await FFmpegKit.execute(command);
    return File(outputPath);
  }

  static String _escape(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll(':', '\\:')
        .replaceAll("'", "\\'");
  }
}

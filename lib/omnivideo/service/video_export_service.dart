import '../model/video_track.dart';

class VideoExportService {
  static String buildCurveCommand(VideoTrack track, String outputPath) {
    final buffer = StringBuffer();

    for (int i = 0; i < track.speedCurve!.length; i++) {
      final seg = track.speedCurve![i];

      buffer.writeln(
          '[0:v]trim=${seg.start.inSeconds}:${seg.end.inSeconds},'
              'setpts=${1 / seg.speed}*PTS[v$i];'
      );
    }

    buffer.write(
        track.speedCurve!.asMap().entries.map((e) => '[v${e.key}]').join()
    );
    buffer.writeln(
        'concat=n=${track.speedCurve!.length}:v=1:a=0[outv]'
    );

    return '''
-i ${track.path}
-filter_complex "${buffer.toString()}"
-map "[outv]"
$outputPath
''';
  }
}

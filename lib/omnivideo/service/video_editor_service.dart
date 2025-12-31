
import 'package:ffmpeg_kit_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_min_gpl/return_code.dart';

class VideoEditorService {
  // Trim video
  static Future<bool> trimVideo({
    required String inputPath,
    required String outputPath,
    required Duration start,
    required Duration end,
  }) async {
    final command = '-i "$inputPath" -ss ${start.inSeconds} -to ${end.inSeconds} -c copy "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }

  // Rotate video
  static Future<bool> rotateVideo({
    required String inputPath,
    required String outputPath,
    required double angle,
  }) async {
    final command =
        '-i "$inputPath" -vf "rotate=${angle}*PI/180:c=black@0" "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }

  // Flip video
  static Future<bool> flipVideo({
    required String inputPath,
    required String outputPath,
    required bool flipHorizontal,
  }) async {
    final command =
        '-i "$inputPath" -vf "${flipHorizontal ? "hflip" : "vflip"}" "$outputPath"';
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    return returnCode != null && ReturnCode.isSuccess(returnCode);
  }
}

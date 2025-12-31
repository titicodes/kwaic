import 'dart:typed_data';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailArgs {
  final String videoPath;
  final int count;
  ThumbnailArgs(this.videoPath, this.count);
}

Future<List<Uint8List>> generateThumbnailsTask(ThumbnailArgs args) async {
  final thumbs = <Uint8List>[];
  final intervalMs = 2000; // default 1s between thumbs

  for (int i = 0; i < args.count; i++) {
    final timeMs = i * intervalMs;
    final bytes = await VideoThumbnail.thumbnailData(
      video: args.videoPath,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 120,
      quality: 75,
      timeMs: timeMs,
    );
    if (bytes != null) thumbs.add(bytes);
  }

  return thumbs;
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PreviewPlayer extends StatelessWidget {
  final VideoPlayerController? controller;

  const PreviewPlayer({Key? key, this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child:
              controller != null && controller!.value.isInitialized
                  ? VideoPlayer(controller!)
                  : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.videocam,
                        size: 60,
                        color: Colors.white24,
                      ),
                    ),
                  ),
        ),
      ),
    );
  }
}

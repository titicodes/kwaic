// timeline_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../nes_scr/controllers/all_app_controller.dart';

class TimelineWidget extends StatelessWidget {
  const TimelineWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 700;
    final timelineHeight = isTablet ? 300.0 : 240.0;

    return SizedBox(
      height: timelineHeight,
      child: Consumer<AAllAppController>(
        builder: (context, controller, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          final centerX = screenWidth / 2;

          // Calculate timeline content width
          final totalSeconds = controller.totalDuration.inMilliseconds / 1000.0;
          final calculatedWidth = totalSeconds * controller.pixelsPerSecond;

          // Minimum width = at least one screen wide (so playhead has space)
          final contentWidth = calculatedWidth > screenWidth ? calculatedWidth : screenWidth;

          return Container(
            color: Colors.black,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Scrollable tracks
                SingleChildScrollView(
                  controller: controller.scrollController, // Shared controller for sync
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SizedBox(
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildVideoTrack(controller),
                        _buildAudioTrack(),
                      ],
                    ),
                  ),
                ),

                // Fixed centered playhead
                _buildCenteredPlayhead(screenWidth),

                // Add clip button
                _buildAddClipButton(centerX),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoTrack(AAllAppController controller) {
    return Container(
      height: 80,
      color: Colors.grey[900],
      child: Stack(
        children: [
          // Render clips
          ...controller.clips.asMap().entries.map((entry) {
            final clip = entry.value;
            final left = (clip.timelineStart.inMilliseconds / 1000.0) * controller.pixelsPerSecond;
            final width = (clip.duration.inMilliseconds / 1000.0) * controller.pixelsPerSecond;

            return Positioned(
              left: left,
              top: 10,
              child: Container(
                width: width,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: clip.frameThumbnails.map((path) {
                      return Expanded(
                        child: Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          }),

          // Empty state message
          if (controller.clips.isEmpty)
            const Center(
              child: Text(
                "Add clips to start editing",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioTrack() {
    return Container(
      height: 40,
      color: Colors.grey[850],
      child: const Center(
        child: Text(
          "Audio track",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildCenteredPlayhead(double screenWidth) {
    return Positioned(
      left: screenWidth / 2 - 1,
      top: 0,
      bottom: 0,
      width: 2,
      child: IgnorePointer(
        child: Container(
          color: const Color(0xFF00D9FF),
          child: Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Color(0xFF00D9FF),
                  shape: BoxShape.circle,
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddClipButton(double centerX) {
    return Positioned(
      left: centerX + 80,
      top: 20,
      child: FloatingActionButton.small(
        backgroundColor: const Color(0xFF00D9FF),
        onPressed: () {
          // Navigate to asset picker or open modal
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NewTimeline extends StatefulWidget {
  const NewTimeline({super.key});

  @override
  State<NewTimeline> createState() => _NewTimelineState();
}

class _NewTimelineState extends State<NewTimeline> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final centerX = screenWidth / 2;
    final isTablet = screenWidth > 700;
    final timelineHeight = isTablet ? 300.0 : 260.0;

    return Scaffold(
      body: Center(
        child: SizedBox(
          child: Container(
            child: GestureDetector(
              onTap: () {},
              child: ClipRect(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: ClampingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: screenWidth,
                          maxWidth: 500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

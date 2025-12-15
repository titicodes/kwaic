import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Bottom sheet for selecting animation effects (In, Out, Combo).
///
/// This uses flutter_animate for robust and declarative animation definitions,
/// with manual control for the GridView preview tiles.
class AnimationSheet extends StatefulWidget {
  final Function(String anim) onApply;

  const AnimationSheet({super.key, required this.onApply});

  @override
  State<AnimationSheet> createState() => _AnimationSheetState();
}

class _AnimationSheetState extends State<AnimationSheet>
    with TickerProviderStateMixin {
  // Define the animation names based on the flutter_animate package effects
  final List<String> inAnims = ['fadeIn', 'slideInLeft', 'zoomIn'];
  final List<String> outAnims = ['fadeOut', 'slideOutRight', 'zoomOut'];
  final List<String> comboAnims = ['bounce', 'elastic']; // Renamed 'bounceInOut' and 'elastic' for cleaner names

  // Map to store AnimationController for each tile, keyed by animation name.
  final Map<String, AnimationController> _controllers = {};

  @override
  void dispose() {
    // Crucial: Dispose all controllers when the sheet is closed.
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search animations',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFF00D9FF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Custom TabBar styling for CapCut aesthetic
            const TabBar(
              indicatorColor: Color(0xFF00D9FF),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'In'),
                Tab(text: 'Out'),
                Tab(text: 'Combo'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _animGrid(inAnims),
                  _animGrid(outAnims),
                  _animGrid(comboAnims),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _animGrid(List<String> anims) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 2.0,
      ),
      itemCount: anims.length,
      itemBuilder: (_, i) {
        String anim = anims[i];

        // FIX: Remove 'const' to allow the use of the .ms extension method.
        final duration = 800.ms;

        // 1. Define the base widget to be animated
        final textWidget = Center(
          child: Text(
            anim,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );

        // 2. Define the animation chain based on the effect name
        Widget animatedWidget;

        // Get the stored controller reference (will be null on first build)
        final controller = _controllers[anim];

        // IMPORTANT: Chain the effects using the flutter_animate extension methods.
        // We use autoPlay: false here because we control it manually later.
        switch (anim) {
          case 'fadeIn':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .fadeIn(duration: duration, curve: Curves.easeIn);
            break;

          case 'slideInLeft':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
            // FIX CHECK: 'begin' takes a constant Offset, which is correct.
                .slide(
              begin: const Offset(-0.8, 0),
              duration: duration,
              curve: Curves.easeOutCubic,
            ).fadeIn(duration: 200.ms);
            break;
          case 'zoomIn':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .scale(
              begin: Offset(0.5, 0.5),  // Using Offset for scaling (0.5 is the scale factor for both X and Y axes)
              end: Offset(1.0, 1.0),    // Ending scale (1.0 means normal size)
              duration: duration,
              curve: Curves.easeOutBack,
            )
                .fadeIn(duration: 200.ms);
            break;

          case 'fadeOut':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .fadeOut(duration: duration, curve: Curves.easeOut);
            break;

          case 'slideOutRight':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
            // FIX CHECK: 'end' takes a constant Offset, which is correct.
                .slide(
              end: const Offset(0.8, 0),
              duration: duration,
              curve: Curves.easeInCubic,
            ).fadeOut(duration: 200.ms);
            break;

          case 'zoomOut':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .scale(
              begin: Offset(1.0, 1.0),  // Starting scale (1.0 means normal size)
              end: Offset(0.5, 0.5),    // Ending scale (0.5 means 50% of original size)
              duration: duration,
              curve: Curves.easeInBack,
            )
                .fadeOut(duration: 200.ms);
            break;

          case 'bounce':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .scale(duration: 400.ms, curve: Curves.easeOutCubic, begin: Offset(1.0, 1.0), end: Offset(0.8, 0.8))
                .then(delay: 100.ms)
                .scale(duration: 800.ms, curve: Curves.bounceOut, begin: Offset(0.8, 0.8), end: Offset(1.1, 1.1))
                .scale(duration: 500.ms, curve: Curves.easeOut, begin: Offset(1.1, 1.1), end: Offset(1.0, 1.0));
            break;

          case 'elastic':
            animatedWidget = textWidget
                .animate(controller: controller, autoPlay: false)
                .scale(duration: 1200.ms, curve: Curves.elasticOut, begin: Offset(0.4, 0.4), end: Offset(1.0, 1.0));
            break;

          default:
            animatedWidget = textWidget;
            break;
        }

        return GestureDetector(
          onTap: () {
            // 3. Apply the selected animation to the clip data
            widget.onApply(anim);

            // 4. Manually trigger the preview animation on the tile
            if (_controllers.containsKey(anim)) {
              _controllers[anim]!.reset();
              _controllers[anim]!.forward();
            }
          },
          child: Container(
            decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!, width: 0.5)),
            // 5. Wrap the final animated widget with another .animate() call
            // to capture the controller reference and start the continuous loop.
            child: animatedWidget.animate(
              onInit: (initController) {
                // Store the controller reference
                _controllers[anim] = initController;
                // Start the continuous preview loop
                initController.repeat(reverse: true);
              },
            ),
          ),
        );
      },
    );
  }
}
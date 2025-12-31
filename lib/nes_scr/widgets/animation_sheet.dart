import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

class AnimationSheet extends StatefulWidget {
  final Function(String anim) onApply;

  const AnimationSheet({super.key, required this.onApply});

  @override
  State<AnimationSheet> createState() => _AnimationSheetState();
}

class _AnimationSheetState extends State<AnimationSheet>
    with TickerProviderStateMixin {
  final List<String> inAnims = ['fadeIn', 'slideInLeft', 'zoomIn'];
  final List<String> outAnims = ['fadeOut', 'slideOutRight', 'zoomOut'];
  final List<String> comboAnims = ['bounce', 'elastic'];

  final List<Map<String, dynamic>> _onlineAnims = [
    {'name': 'Confetti', 'url': 'https://assets9.lottiefiles.com/packages/lf20_7q4l4t.json'},
    {'name': 'Fireworks', 'url': 'https://assets10.lottiefiles.com/packages/lf20_1j5j0q.json'},
    {'name': 'Heart Burst', 'url': 'https://assets8.lottiefiles.com/packages/lf20_1j5j0q.json'},
    {'name': 'Sparkle', 'url': 'https://assets4.lottiefiles.com/packages/lf20_1j5j0q.json'},
    {'name': 'Star Explosion', 'url': 'https://assets3.lottiefiles.com/packages/lf20_1j5j0q.json'},
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                          borderSide: BorderSide.none,
                        ),
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
            const TabBar(
              indicatorColor: Color(0xFF00D9FF),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'In'),
                Tab(text: 'Out'),
                Tab(text: 'Combo'),
                Tab(text: 'Online'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _animGrid(inAnims),
                  _animGrid(outAnims),
                  _animGrid(comboAnims),
                  _buildOnlineGrid(),
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
        final String anim = anims[i];
        final Duration duration = 800.ms;

        return GestureDetector(
          onTap: () {
            widget.onApply(anim);
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!, width: 0.5),
            ),
            child: Center(
              child: Text(
                anim,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            )
                .animate(
              onPlay: (controller) => controller.repeat(reverse: true),
            )
                .applyEffect(anim, duration),
          ),
        );
      },
    );
  }

  Widget _buildOnlineGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: _onlineAnims.length,
      itemBuilder: (_, i) {
        final anim = _onlineAnims[i];
        return GestureDetector(
          onTap: () {
            widget.onApply('lottie:${anim['url']}');
            Navigator.pop(context);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Lottie.network(
              anim['url'],
              fit: BoxFit.contain,
              repeat: true,
            ),
          ),
        );
      },
    );
  }
}

extension AnimationEffects on Widget {
  Widget applyEffect(String name, Duration duration) {
    final anim = this.animate();

    switch (name) {
      case 'fadeIn':
        return anim.fadeIn(duration: duration, curve: Curves.easeOut);

      case 'fadeOut':
        return anim.fadeOut(duration: duration, curve: Curves.easeIn);

      case 'slideInLeft':
        return anim.slide(begin: const Offset(-1, 0), duration: duration);

      case 'slideInRight':
        return anim.slide(begin: const Offset(1, 0), duration: duration);

      case 'slideInUp':
        return anim.slide(begin: const Offset(0, 1), duration: duration);

      case 'slideInDown':
        return anim.slide(begin: const Offset(0, -1), duration: duration);

      case 'slideOutLeft':
        return anim.slide(end: const Offset(-1, 0), duration: duration);

      case 'slideOutRight':
        return anim.slide(end: const Offset(1, 0), duration: duration);

      case 'slideOutUp':
        return anim.slide(end: const Offset(0, -1), duration: duration);

      case 'slideOutDown':
        return anim.slide(end: const Offset(0, 1), duration: duration);

      case 'zoomIn':
        return anim.scale(
          begin: const Offset(0.3, 0.3),
          duration: duration,
          curve: Curves.elasticOut,
        );

      case 'zoomOut':
        return anim.scale(
          end: const Offset(0.3, 0.3),
          duration: duration,
        );

      case 'shimmer':
        return anim.shimmer(duration: duration);

      default:
        return this; // no animation
    }
  }
}

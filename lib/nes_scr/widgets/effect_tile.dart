import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class EffectSheet extends StatelessWidget {
  final Function(String effect) onApply;

   EffectSheet({super.key, required this.onApply});

  // List of online Lottie URLs (example links, you can replace them with others from LottieFiles)
  final List<String> effects = [
    'https://assets10.lottiefiles.com/packages/lf20_s1xjylhb.json', // glitch effect
    'https://assets10.lottiefiles.com/packages/lf20_qdy9sbyb.json', // fire effect
    'https://assets10.lottiefiles.com/packages/lf20_qmt3sdrr.json', // rain effect
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.66,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
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
                    decoration: InputDecoration(hintText: 'Search effects'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: 'Trending'),
              Tab(text: 'Christmas'),
              Tab(text: 'New Year'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _effectGrid(effects), // Trending effects
                _effectGrid(effects), // Christmas effects (same as Trending)
                _effectGrid(effects), // New Year effects (same as Trending)
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Grid of Lottie previews
  Widget _effectGrid(List<String> effectsList) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
      itemCount: effectsList.length,
      itemBuilder: (_, i) {
        String effectUrl = effectsList[i];
        return GestureDetector(
          onTap: () => onApply(effectUrl), // Apply the selected effect
          child: Container(
            margin: EdgeInsets.all(8),
            color: Colors.grey[800],
            child: Center(
              child: Lottie.network(
                effectUrl,
                width: 100, // Customize size
                height: 100,
                fit: BoxFit.cover,
                repeat: true, // Set to false to stop looping animation
              ),
            ),
          ),
        );
      },
    );
  }
}

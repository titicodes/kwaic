import 'package:flutter/material.dart';
// You will need to install this package: flutter pub add flutter_svg
import 'package:flutter_svg/flutter_svg.dart';

class StickerSheet extends StatelessWidget {
  final Function(String url) onStickerSelected;

   StickerSheet({super.key, required this.onStickerSelected});

  // OpenMoji Emojis (Already in your original code)
  final List<String> _emojiCodes = [
    '1F600', '1F602', '1F923', '1F60D', '1F60A', '1F970', '1F60E', '1F44C', '1F44D', '1F44F',
    '1F638', '1F436', '1F37B', '1F389', '1F525', '1F4A9',
  ];

  // Example Stickers from Flaticon (Attribution may be required for free tier)
  final List<String> _trendingStickers = [
    // Source: Flaticon - search term 'social media'
    'https://cdn-icons-png.flaticon.com/512/3670/3670151.png', // Heart for Instagram (using PNG, as SVG URLs are complex)
    'https://cdn-icons-png.flaticon.com/512/3670/3670220.png', // YouTube logo
    'https://cdn-icons-png.flaticon.com/512/3670/3670126.png', // TikTok logo
    'https://cdn-icons-png.flaticon.com/512/3670/3670077.png', // Facebook logo
    'https://cdn-icons-png.flaticon.com/512/3670/3670233.png', // Twitter/X logo
    'https://cdn-icons-png.flaticon.com/512/1000/1000889.png', // Star
    'https://cdn-icons-png.flaticon.com/512/4207/4207248.png', // Subscribe Button
    'https://cdn-icons-png.flaticon.com/512/6073/6073994.png', // Arrow pointing down
  ];

  // Example Stickers from Craftwork's Open Stickers (Free for commercial use, attribution appreciated)
  final List<String> _funnyStickers = [
    // These are often simpler SVGs, which is better for performance.
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-38.svg', // Pizza slice
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-3.svg', // Ghost
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-79.svg', // Thumbs up
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-11.svg', // Banana
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-12.svg', // Cactus
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-34.svg', // Heart Eyes
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-78.svg', // Happy Face
    'https://openstickers.craftwork.design/wp-content/uploads/2021/07/openstickers-16.svg', // Drink
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Match number of tabs
      child: Container(
        height: MediaQuery.of(context).size.height * 0.66,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search stickers',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
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
            // Custom TabBar with theme styles for CapCut look
            TabBar(
              isScrollable: true,
              indicatorColor: const Color(0xFF00D9FF),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Emojis'),
                Tab(text: 'Trending'),
                Tab(text: 'Funny'),
                Tab(text: 'Love'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // 1. Emojis (using original OpenMoji)
                  _buildStickerGrid(_emojiCodes, isEmoji: true),
                  // 2. Trending (using Flaticon PNGs/JPEGs for common social icons)
                  _buildStickerGrid(_trendingStickers, isSvg: false),
                  // 3. Funny (using Craftwork SVGs)
                  _buildStickerGrid(_funnyStickers, isSvg: true),
                  // 4. Love (Placeholder for another category)
                  const Center(child: Text('Coming Soon...', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the GridView for different sticker sources/types
  Widget _buildStickerGrid(List<String> urls, {bool isSvg = false, bool isEmoji = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) {
        final url = urls[i];
        Widget stickerWidget;

        if (isEmoji) {
          // OpenMoji SVG URL for a standard emoji
          final openMojiUrl = 'https://openmoji.org/data/color/svg/$url.svg';
          stickerWidget = SvgPicture.network(
            openMojiUrl,
            width: 40,
            height: 40,
            placeholderBuilder: (BuildContext context) => const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        } else if (isSvg) {
          // General SVG sticker from a source like Craftwork
          stickerWidget = SvgPicture.network(
            url,
            width: 40,
            height: 40,
            placeholderBuilder: (BuildContext context) => const SizedBox(
              width: 40,
              height: 40,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        } else {
          // PNG/JPEG from a source like Flaticon
          stickerWidget = Image.network(
            url,
            width: 40,
            height: 40,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(
                width: 40,
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
          );
        }

        return GestureDetector(
          onTap: () => onStickerSelected(isEmoji ? 'https://openmoji.org/data/color/svg/$url.svg' : url),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: stickerWidget,
          ),
        );
      },
    );
  }
}
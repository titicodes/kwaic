import 'package:flutter/material.dart';

class SoundFXSheet extends StatelessWidget {
  const SoundFXSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // Number of tabs
      child: Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 5,
                color: Colors.grey),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sound Effects',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search sound effects',
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none),
                  suffixIcon: const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tabs
            const TabBar(
              tabs: [
                Tab(text: 'Trending'),
                Tab(text: 'Hits'),
                Tab(text: 'TikTok'),
                Tab(text: 'Christmas'),
              ],
            ),
            // Content
            const Expanded(
              child: TabBarView(
                children: [
                  _SoundFXList(),
                  _SoundFXList(),
                  _SoundFXList(),
                  _SoundFXList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoundFXList extends StatelessWidget {
  const _SoundFXList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 20, // Placeholder
      itemBuilder: (_, i) => ListTile(
        leading: const Icon(Icons.graphic_eq, color: Colors.white70),
        title: Text('Sound Effect $i', style: const TextStyle(color: Colors.white)),
        subtitle: Text('0:0${i % 5 + 1}', style: const TextStyle(color: Colors.white54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
            IconButton(icon: const Icon(Icons.download), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
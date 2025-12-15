import 'package:flutter/material.dart';

class FilterSheet extends StatelessWidget {
  final Function(String filter) onApply;

  const FilterSheet({super.key, required this.onApply});

  final List<Map<String, String>> filters = const [
    {'name': 'Original', 'id': 'none'},
    {'name': 'Vintage', 'id': 'vintage'},
    {'name': 'Cinematic', 'id': 'cinematic'},
    {'name': 'Warm', 'id': 'warm'},
    {'name': 'Cool', 'id': 'cool'},
    {'name': 'Black & White', 'id': 'bw'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Filters',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: filters.length,
              itemBuilder: (_, i) {
                final f = filters[i];
                return GestureDetector(
                  onTap: () {
                    onApply(f['id']!);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[800],
                    ),
                    child: Center(
                      child: Text(
                        f['name']!,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

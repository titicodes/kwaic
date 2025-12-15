import 'package:flutter/material.dart';

/// Top navigation bar with back, project name, help, and export
class TopBar extends StatelessWidget {
  final String projectName;
  final VoidCallback onBack;
  final VoidCallback onExport;
  final VoidCallback onHelp;

  const TopBar({
    super.key,
    required this.projectName,
    required this.onBack,
    required this.onExport,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56 + MediaQuery.of(context).padding.top,
      color: Colors.black,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
      ),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: onBack,
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),

          const Spacer(),

          // Project Name (centered)
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                projectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          const Spacer(),

          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: onHelp,
          ),

          const SizedBox(width: 8),

          // Export button (purple capsule)
          GestureDetector(
            onTap: onExport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF9F70FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
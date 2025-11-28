// ========================================
// PRODUCTION ENHANCEMENT 5: PROJECT AUTOSAVE
// ========================================

import 'dart:async';
import 'package:flutter/material.dart';

class AutosaveManager {
  Timer? _autosaveTimer;
  final Duration autosaveInterval;
  final Function() onAutosave;
  DateTime? _lastSaveTime;
  bool _hasUnsavedChanges = false;

  AutosaveManager({
    required this.onAutosave,
    this.autosaveInterval = const Duration(minutes: 2),
  });

  // Start autosave timer
  void start() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer.periodic(autosaveInterval, (timer) {
      if (_hasUnsavedChanges) {
        debugPrint('💾 Autosaving project...');
        onAutosave();
        _lastSaveTime = DateTime.now();
        _hasUnsavedChanges = false;
      }
    });
    debugPrint('⏰ Autosave started: every ${autosaveInterval.inMinutes} minutes');
  }

  // Stop autosave timer
  void stop() {
    _autosaveTimer?.cancel();
    _autosaveTimer = null;
    debugPrint('⏸️ Autosave stopped');
  }

  // Mark that changes have been made
  void markChanged() {
    _hasUnsavedChanges = true;
  }

  // Force save now
  void saveNow() {
    if (_hasUnsavedChanges) {
      onAutosave();
      _lastSaveTime = DateTime.now();
      _hasUnsavedChanges = false;
    }
  }

  DateTime? get lastSaveTime => _lastSaveTime;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  void dispose() {
    _autosaveTimer?.cancel();
  }
}

// Autosave Status Indicator
class AutosaveStatusIndicator extends StatefulWidget {
  final AutosaveManager autosaveManager;

  const AutosaveStatusIndicator({
    Key? key,
    required this.autosaveManager,
  }) : super(key: key);

  @override
  State<AutosaveStatusIndicator> createState() => _AutosaveStatusIndicatorState();
}

class _AutosaveStatusIndicatorState extends State<AutosaveStatusIndicator> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every second to show time since last save
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lastSave = widget.autosaveManager.lastSaveTime;
    final hasChanges = widget.autosaveManager.hasUnsavedChanges;

    String statusText = 'Not saved';
    IconData statusIcon = Icons.cloud_off;
    Color statusColor = Colors.grey;

    if (lastSave != null) {
      final diff = DateTime.now().difference(lastSave);
      if (hasChanges) {
        statusText = 'Unsaved changes';
        statusIcon = Icons.cloud_upload;
        statusColor = Colors.orange;
      } else if (diff.inSeconds < 10) {
        statusText = 'Saved just now';
        statusIcon = Icons.cloud_done;
        statusColor = Colors.green;
      } else if (diff.inMinutes < 1) {
        statusText = 'Saved ${diff.inSeconds}s ago';
        statusIcon = Icons.cloud_done;
        statusColor = Colors.green;
      } else {
        statusText = 'Saved ${diff.inMinutes}m ago';
        statusIcon = Icons.cloud_done;
        statusColor = Colors.green;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


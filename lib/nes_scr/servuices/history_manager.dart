// ========================================
// PRODUCTION ENHANCEMENT 1: UNDO/REDO STACK WITH LIMIT
// ========================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/eitor_state.dart';
import 'cloud_save_service.dart';

class HistoryManager {
  static const int MAX_HISTORY_SIZE = 50; // Limit to prevent memory issues
  final List<EditorState> _history = [];
  int _currentIndex = -1;

  // Add state to history with size limit
  void saveState(EditorState state) {
    // Remove any redo states after current position
    if (_currentIndex < _history.length - 1) {
      _history.removeRange(_currentIndex + 1, _history.length);
    }

    // Add new state
    _history.add(state);
    _currentIndex = _history.length - 1;

    // Enforce max size by removing oldest states
    if (_history.length > MAX_HISTORY_SIZE) {
      final removeCount = _history.length - MAX_HISTORY_SIZE;
      _history.removeRange(0, removeCount);
      _currentIndex -= removeCount;
    }

    debugPrint('📚 History: ${_history.length} states, current: $_currentIndex');
  }

  // Undo operation
  EditorState? undo() {
    if (!canUndo()) return null;
    _currentIndex--;
    debugPrint('⬅️ Undo: Moving to index $_currentIndex');
    return _history[_currentIndex];
  }

  // Redo operation
  EditorState? redo() {
    if (!canRedo()) return null;
    _currentIndex++;
    debugPrint('➡️ Redo: Moving to index $_currentIndex');
    return _history[_currentIndex];
  }

  bool canUndo() => _currentIndex > 0;
  bool canRedo() => _currentIndex < _history.length - 1;

  int get historySize => _history.length;
  int get currentIndex => _currentIndex;

  void clear() {
    _history.clear();
    _currentIndex = -1;
  }
}








// Project Selector Dialog
class ProjectSelectorDialog extends StatefulWidget {
  const ProjectSelectorDialog({super.key});

  @override
  State<ProjectSelectorDialog> createState() => _ProjectSelectorDialogState();
}

class _ProjectSelectorDialogState extends State<ProjectSelectorDialog> {
  List<Map<String, dynamic>> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    final projects = await CloudSaveService.getAllProjects();
    setState(() {
      _projects = projects;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Projects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                ),
              )
            else if (_projects.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.white30),
                      SizedBox(height: 16),
                      Text(
                        'No saved projects',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return _buildProjectCard(project);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final timestamp = DateTime.parse(project['timestamp']);
    final timeAgo = _getTimeAgo(timestamp);

    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.video_library, color: Color(0xFF00D9FF)),
        ),
        title: Text(
          project['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          timeAgo,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          color: const Color(0xFF2A2A2A),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Open', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, project['id']),
            ),
            PopupMenuItem(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await CloudSaveService.deleteProject(project['id']);
                _loadProjects();
              },
            ),
          ],
        ),
        onTap: () => Navigator.pop(context, project['id']),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

// Continue with Autosave in next artifact...

// ========================================
// PRODUCTION ENHANCEMENT 4: CLOUD SAVE/LOAD
// ========================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/timeline_item.dart';

class CloudSaveService {
  static const String PROJECTS_KEY = 'video_editor_projects';
  static const String LAST_PROJECT_KEY = 'last_project_id';

  // Save project to cloud/local storage
  static Future<bool> saveProject({
    required String projectId,
    required String projectName,
    required List<TimelineItem> clips,
    required List<TimelineItem> audioItems,
    required List<TimelineItem> textItems,
    required List<TimelineItem> overlayItems,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final projectData = {
        'id': projectId,
        'name': projectName,
        'timestamp': DateTime.now().toIso8601String(),
        'clips': clips.map((c) => c.toJson()).toList(),
        'audio': audioItems.map((a) => a.toJson()).toList(),
        'text': textItems.map((t) => t.toJson()).toList(),
        'overlays': overlayItems.map((o) => o.toJson()).toList(),
      };

      // Get existing projects
      final projectsJson = prefs.getString(PROJECTS_KEY);
      final projects = projectsJson != null ? jsonDecode(projectsJson) as List : [];

      // Update or add project
      final existingIndex = projects.indexWhere((p) => p['id'] == projectId);
      if (existingIndex >= 0) {
        projects[existingIndex] = projectData;
      } else {
        projects.add(projectData);
      }

      // Save back to storage
      await prefs.setString(PROJECTS_KEY, jsonEncode(projects));
      await prefs.setString(LAST_PROJECT_KEY, projectId);

      debugPrint('💾 Project saved: $projectName');
      return true;
    } catch (e) {
      debugPrint('❌ Save project error: $e');
      return false;
    }
  }

  // Load project from cloud/local storage
  static Future<Map<String, dynamic>?> loadProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getString(PROJECTS_KEY);

      if (projectsJson == null) return null;

      final projects = jsonDecode(projectsJson) as List;
      final project = projects.firstWhere(
            (p) => p['id'] == projectId,
        orElse: () => null,
      );

      if (project != null) {
        debugPrint('📂 Project loaded: ${project['name']}');
      }

      return project;
    } catch (e) {
      debugPrint('❌ Load project error: $e');
      return null;
    }
  }

  // Get all saved projects
  static Future<List<Map<String, dynamic>>> getAllProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getString(PROJECTS_KEY);

      if (projectsJson == null) return [];

      final projects = jsonDecode(projectsJson) as List;
      return projects.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Get projects error: $e');
      return [];
    }
  }

  // Delete project
  static Future<bool> deleteProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projectsJson = prefs.getString(PROJECTS_KEY);

      if (projectsJson == null) return false;

      final projects = jsonDecode(projectsJson) as List;
      projects.removeWhere((p) => p['id'] == projectId);

      await prefs.setString(PROJECTS_KEY, jsonEncode(projects));

      debugPrint('🗑️ Project deleted: $projectId');
      return true;
    } catch (e) {
      debugPrint('❌ Delete project error: $e');
      return false;
    }
  }
}
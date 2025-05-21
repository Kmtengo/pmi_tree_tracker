import 'package:flutter/foundation.dart';
import '../models/tree_models.dart';
import '../services/project_service.dart';

class ProjectViewModel extends ChangeNotifier {
  final ProjectService _projectService = ProjectService();
  
  List<Project> _projects = [];
  List<Project> get projects => _projects;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  // Load all projects
  Future<void> loadProjects() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _projects = await _projectService.getAllProjects();
    } catch (e) {
      _error = 'Failed to load projects: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Add a new project
  Future<bool> addProject({
    required String title,
    required String description,
    required String location,
    required int targetTrees,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      Project newProject = Project(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        location: location,
        startDate: DateTime.now(),
        endDate: endDate,
        status: 'Active',
        targetTrees: targetTrees,
        plantedTrees: 0,
      );
      
      bool success = await _projectService.addProject(newProject);
      
      if (success) {
        await loadProjects(); // Reload projects after adding
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to add project: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update project tree count
  Future<bool> updateProjectTreeCount(String projectId, int treesPlanted) async {
    try {
      bool success = await _projectService.updateProjectTreeCount(projectId, treesPlanted);
      
      if (success) {
        await loadProjects(); // Reload projects after updating
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to update project tree count: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Get active projects
  List<Project> get activeProjects => _projects.where((project) => project.status == 'Active').toList();
  
  // Get completed projects
  List<Project> get completedProjects => _projects.where((project) => project.status == 'Completed').toList();
  
  // Get projects by location
  List<Project> getProjectsByLocation(String location) {
    return _projects.where((project) => project.location.toLowerCase() == location.toLowerCase()).toList();
  }
  
  // Get project progress percentage
  double getProjectProgress(String projectId) {
    try {
      Project project = _projects.firstWhere((p) => p.id == projectId);
      return project.plantedTrees / project.targetTrees;
    } catch (e) {
      return 0.0;
    }
  }
}

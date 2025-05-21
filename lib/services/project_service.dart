import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_models.dart';

// Service class for project-related operations
class ProjectService {
  // Get all projects
  Future<List<Project>> getAllProjects() async {
    try {
      // For demo, use local storage
      List<Project> mockProjects = await _getMockProjects();
      return mockProjects;
    } catch (e) {
      print('Error getting projects: $e');
      return [];
    }
  }
  
  // Add a new project
  Future<bool> addProject(Project project) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> projectsJson = prefs.getStringList('projects') ?? [];
      projectsJson.add(jsonEncode(project.toJson()));
      await prefs.setStringList('projects', projectsJson);
      return true;
    } catch (e) {
      print('Error adding project: $e');
      return false;
    }
  }
  
  // Get projects by status
  Future<List<Project>> getProjectsByStatus(String status) async {
    try {
      List<Project> allProjects = await getAllProjects();
      return allProjects.where((project) => project.status == status).toList();
    } catch (e) {
      print('Error getting projects by status: $e');
      return [];
    }
  }
  
  // Get project by ID
  Future<Project?> getProjectById(String projectId) async {
    try {
      List<Project> allProjects = await getAllProjects();
      return allProjects.firstWhere((project) => project.id == projectId);
    } catch (e) {
      print('Error getting project by ID: $e');
      return null;
    }
  }
  
  // Update project tree count
  Future<bool> updateProjectTreeCount(String projectId, int treesPlanted) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> projectsJson = prefs.getStringList('projects') ?? [];
      List<Project> projects = projectsJson.map((pj) => Project.fromJson(jsonDecode(pj))).toList();
      
      int projectIndex = projects.indexWhere((p) => p.id == projectId);
      if (projectIndex != -1) {
        Project existingProject = projects[projectIndex];
        Project updatedProject = Project(
          id: existingProject.id,
          title: existingProject.title,
          description: existingProject.description,
          location: existingProject.location,
          startDate: existingProject.startDate,
          endDate: existingProject.endDate,
          status: existingProject.status,
          targetTrees: existingProject.targetTrees,
          plantedTrees: existingProject.plantedTrees + treesPlanted,
        );
        
        projects[projectIndex] = updatedProject;
        projectsJson = projects.map((p) => jsonEncode(p.toJson())).toList();
        await prefs.setStringList('projects', projectsJson);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating project tree count: $e');
      return false;
    }
  }
  
  // Mock data for projects
  Future<List<Project>> _getMockProjects() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();    List<String> projectsJson = prefs.getStringList('projects') ?? [];
    
    // If there are no projects in storage, create mock data
    if (projectsJson.isEmpty) {
      List<Project> mockProjects = [
        Project(
          id: '1',
          title: 'Kisumu Urban Forest Initiative',
          description: 'Reforestation program in urban Kisumu',
          location: 'Kisumu',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          status: 'Active',
          targetTrees: 1000,
          plantedTrees: 657,
        ),
        Project(
          id: '2',
          title: 'Nairobi Green Belt',
          description: 'Creating a green belt around Nairobi',
          location: 'Nairobi',
          startDate: DateTime.now().subtract(const Duration(days: 60)),
          status: 'Active',
          targetTrees: 2000,
          plantedTrees: 1345,
        ),
        Project(
          id: '3',
          title: 'Coastal Mangrove Restoration',
          description: 'Restoring mangrove forests along the Kenyan coast',
          location: 'Mombasa',
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          status: 'Active',
          targetTrees: 5000,
          plantedTrees: 3200,
        ),
      ];
      
      // Save mock data to local storage
      projectsJson = mockProjects.map((project) => jsonEncode(project.toJson())).toList();
      await prefs.setStringList('projects', projectsJson);
      return mockProjects;
    }
    
    // Parse projects from storage
    return projectsJson.map((pj) => Project.fromJson(jsonDecode(pj))).toList();
  }
}

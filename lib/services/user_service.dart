import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_models.dart';

// Service class for user-related operations
class UserService {
  // Current user information
  static User? currentUser;

  // Login user
  Future<bool> login(String email, String password) async {
    try {
      // For demo, we will use mock data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await _createMockUserIfNeeded();
      
      String? userJson = prefs.getString('currentUser');
      if (userJson != null) {
        currentUser = User.fromJson(jsonDecode(userJson));
        return true;
      }
      
      // Simulate login with mock user
      List<String> usersJson = prefs.getStringList('users') ?? [];
      List<User> users = usersJson.map((uj) => User.fromJson(jsonDecode(uj))).toList();
      
      User? matchingUser = users.isNotEmpty ? users[0] : null;
      
      if (matchingUser != null) {
        currentUser = matchingUser;
        await prefs.setString('currentUser', jsonEncode(matchingUser.toJson()));
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    }
  }
  
  // Logout user
  Future<bool> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUser');
      currentUser = null;
      return true;
    } catch (e) {
      print('Error logging out: $e');
      return false;
    }
  }
  
  // Get current user
  Future<User?> getCurrentUser() async {
    if (currentUser != null) {
      return currentUser;
    }
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userJson = prefs.getString('currentUser');
      
      if (userJson != null) {
        currentUser = User.fromJson(jsonDecode(userJson));
        return currentUser;
      }
      
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Update in users list
      List<String> usersJson = prefs.getStringList('users') ?? [];
      List<User> users = usersJson.map((uj) => User.fromJson(jsonDecode(uj))).toList();
      
      int userIndex = users.indexWhere((u) => u.id == updatedUser.id);
      if (userIndex != -1) {
        users[userIndex] = updatedUser;
        usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
        await prefs.setStringList('users', usersJson);
        
        // Update current user if it's the same
        if (currentUser != null && currentUser!.id == updatedUser.id) {
          currentUser = updatedUser;
          await prefs.setString('currentUser', jsonEncode(updatedUser.toJson()));
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // Update user stats
  Future<bool> updateUserStats({int? treesPlanted, int? projectsJoined, int? treesVerified}) async {
    try {
      User? user = await getCurrentUser();
      
      if (user != null) {
        User updatedUser = User(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          region: user.region,
          treesPlanted: treesPlanted ?? user.treesPlanted,
          projectsJoined: projectsJoined ?? user.projectsJoined,
          treesVerified: treesVerified ?? user.treesVerified,
        );
        
        return await updateUserProfile(updatedUser);
      }
      
      return false;
    } catch (e) {
      print('Error updating user stats: $e');
      return false;
    }
  }
  
  // Update user
  Future<bool> updateUser(User user) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Update current user
      await prefs.setString('currentUser', jsonEncode(user.toJson()));
      
      // Also update in users list
      List<String> usersJson = prefs.getStringList('users') ?? [];
      List<User> users = usersJson.map((uj) => User.fromJson(jsonDecode(uj))).toList();
      
      int userIndex = users.indexWhere((u) => u.id == user.id);
      if (userIndex >= 0) {
        users[userIndex] = user;
        
        // Save updated users list
        List<String> updatedUsersJson = users.map((u) => jsonEncode(u.toJson())).toList();
        await prefs.setStringList('users', updatedUsersJson);
      }
      
      currentUser = user;
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }
  
  // Create mock user if not exists
  Future<void> _createMockUserIfNeeded() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? usersJson = prefs.getStringList('users');
    
    if (usersJson == null || usersJson.isEmpty) {
      User mockUser = User(
        id: 'user1',
        name: 'John Doe',
        email: 'john.doe@example.com',
        role: 'coordinator',
        region: 'Nairobi',
        treesPlanted: 324,
        projectsJoined: 12,
        treesVerified: 287,
      );
      
      usersJson = [jsonEncode(mockUser.toJson())];
      await prefs.setStringList('users', usersJson);
    }
  }
}

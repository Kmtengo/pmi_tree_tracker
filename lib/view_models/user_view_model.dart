import 'package:flutter/foundation.dart';
import '../models/tree_models.dart';
import '../services/user_service.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  bool get isLoggedIn => _currentUser != null;
  
  // Initialize the view model
  Future<void> initialize() async {
    await loadCurrentUser();
  }
  
  // Load current user
  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentUser = await _userService.getCurrentUser();
    } catch (e) {
      _error = 'Failed to load user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Login user
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      bool success = await _userService.login(email, password);
      
      if (success) {
        await loadCurrentUser();
      } else {
        _error = 'Invalid email or password';
      }
      
      return success;
    } catch (e) {
      _error = 'Login failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Logout user
  Future<bool> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      bool success = await _userService.logout();
      
      if (success) {
        _currentUser = null;
      }
      
      return success;
    } catch (e) {
      _error = 'Logout failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (_currentUser == null) {
        _error = 'No user logged in';
        return false;
      }
      
      User updatedUser = User(
        id: _currentUser!.id,
        name: name,
        email: email,
        phone: phone,
        role: _currentUser!.role,
        team: _currentUser!.team,
      );
      
      bool success = await _userService.updateUser(updatedUser);
      
      if (success) {
        _currentUser = updatedUser;
      } else {
        _error = 'Failed to update profile';
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update tree count for user
  Future<bool> updateTreeCount(int additionalTrees) async {
    try {
      return await _userService.updateUserStats(
        treesPlanted: (_currentUser?.treesPlanted ?? 0) + additionalTrees,
      );
    } catch (e) {
      _error = 'Failed to update tree count: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Update project count for user
  Future<bool> updateProjectCount() async {
    try {
      return await _userService.updateUserStats(
        projectsJoined: (_currentUser?.projectsJoined ?? 0) + 1,
      );
    } catch (e) {
      _error = 'Failed to update project count: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Update verified trees count for user
  Future<bool> updateVerifiedTreesCount(int additionalTrees) async {
    try {
      return await _userService.updateUserStats(
        treesVerified: (_currentUser?.treesVerified ?? 0) + additionalTrees,
      );
    } catch (e) {
      _error = 'Failed to update verified trees count: $e';
      notifyListeners();
      return false;
    }
  }
}

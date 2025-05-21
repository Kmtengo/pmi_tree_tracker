import 'package:flutter/foundation.dart';
import '../models/tree_models.dart';
import '../services/tree_service.dart';
import '../services/dataverse_service.dart';

class TreeViewModel extends ChangeNotifier {
  final TreeService _treeService = TreeService();
  final DataverseService _dataverseService = DataverseService();
  
  List<Tree> _trees = [];
  List<Tree> get trees => _trees;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
    // Load all trees
  Future<void> loadTrees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Try to get trees from Dataverse first, fall back to local service
      try {
        _trees = await _dataverseService.getTrees();
      } catch (e) {
        print('Error fetching from Dataverse, falling back to local storage: $e');
        _trees = await _treeService.getAllTrees();
      }
    } catch (e) {
      _error = 'Failed to load trees: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Add a new tree
  Future<bool> addTree({
    required String species,
    required String location,
    required int quantity,
    String? photoUrl,
    String? notes,
    String? teamName,
    double? latitude,
    double? longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Get current user ID (would come from auth service in a real app)
      String planterId = 'user1';      
      Tree newTree = Tree(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        species: species,
        location: location,
        quantity: quantity,
        plantingDate: DateTime.now(),
        planterId: planterId,
        photoUrl: photoUrl,
        teamName: teamName,
        latitude: latitude,
        longitude: longitude,
      );
      
      // Try to add to Dataverse first, fall back to local service if failed
      bool success;
      try {
        success = await _dataverseService.addTree(newTree);
      } catch (e) {
        print('Error adding to Dataverse, falling back to local storage: $e');
        success = await _treeService.addTree(newTree);
      }
      
      if (success) {
        await loadTrees(); // Reload trees after adding
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to add tree: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
    // Verify a tree
  Future<bool> verifyTree(String treeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find the tree first
      int treeIndex = _trees.indexWhere((tree) => tree.id == treeId);
      if (treeIndex == -1) {
        _error = 'Tree not found';
        return false;
      }
      
      // Create a verified version of the tree
      Tree tree = _trees[treeIndex];
      Tree verifiedTree = Tree(
        id: tree.id,
        species: tree.species,
        location: tree.location,
        quantity: tree.quantity,
        plantingDate: tree.plantingDate,
        planterId: tree.planterId,
        photoUrl: tree.photoUrl,
        isVerified: true,
        teamName: tree.teamName,
        growthUpdates: tree.growthUpdates,
        latitude: tree.latitude,
        longitude: tree.longitude,
      );
      
      // Try to update in Dataverse first, then fall back to local service
      bool success;
      try {
        success = await _dataverseService.updateTree(verifiedTree);
      } catch (e) {
        print('Error verifying in Dataverse, falling back to local storage: $e');
        success = await _treeService.verifyTree(treeId);
      }
      
      if (success) {
        await loadTrees(); // Reload trees after verifying
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to verify tree: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
    // Add a growth update to an existing tree
  Future<bool> addGrowthUpdate({
    required String treeId,
    required String notes,
    String? photoUrl,
    double? heightCm,
    String? healthStatus,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Find the tree to update
      int treeIndex = _trees.indexWhere((tree) => tree.id == treeId);
      if (treeIndex == -1) {
        _error = 'Tree not found';
        return false;
      }
      
      // Create updated tree with new growth update
      Tree updatedTree = _trees[treeIndex].addGrowthUpdate(
        notes: notes,
        photoUrl: photoUrl,
        heightCm: heightCm,
        healthStatus: healthStatus,
      );
      
      // Update tree in the service (try Dataverse first, then local)
      bool success;
      try {
        success = await _dataverseService.updateTree(updatedTree);
      } catch (e) {
        print('Error updating in Dataverse, falling back to local storage: $e');
        success = await _treeService.updateTree(updatedTree);
      }
      
      if (success) {
        // Update local list
        List<Tree> updatedTrees = List<Tree>.from(_trees);
        updatedTrees[treeIndex] = updatedTree;
        _trees = updatedTrees;
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to add growth update: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get unverified trees
  List<Tree> get unverifiedTrees => _trees.where((tree) => !tree.isVerified).toList();
  
  // Get verified trees
  List<Tree> get verifiedTrees => _trees.where((tree) => tree.isVerified).toList();
  
  // Get trees by location
  List<Tree> getTreesByLocation(String location) {
    return _trees.where((tree) => tree.location.toLowerCase() == location.toLowerCase()).toList();
  }
    // Get trees by species
  List<Tree> getTreesBySpecies(String species) {
    return _trees.where((tree) => tree.species.toLowerCase() == species.toLowerCase()).toList();
  }
  
  // Synchronize local data with Dataverse when online
  Future<bool> synchronizeWithDataverse() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      bool success = await _dataverseService.synchronizeData();
      
      if (success) {
        // Reload trees to get any updates from the server
        await loadTrees();
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to synchronize data: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

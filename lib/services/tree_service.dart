import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_models.dart';

// Service class for tree-related operations
class TreeService {
  // Mock API URL - replace with actual API URL in production
  final String apiUrl = 'https://api.example.com/trees';
  
  // Get all trees
  Future<List<Tree>> getAllTrees() async {
    try {
      // For demo, we will use local storage instead of actual API
      List<Tree> mockTrees = await _getMockTrees();
      return mockTrees;
    } catch (e) {
      print('Error getting trees: $e');
      return [];
    }
  }
  
  // Add a new tree record
  Future<bool> addTree(Tree tree) async {
    try {
      // For demo, we will store in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> treesJson = prefs.getStringList('trees') ?? [];
      treesJson.add(jsonEncode(tree.toJson()));
      await prefs.setStringList('trees', treesJson);
      return true;
    } catch (e) {
      print('Error adding tree: $e');
      return false;
    }
  }
  
  // Get trees for a specific user
  Future<List<Tree>> getUserTrees(String userId) async {
    try {
      List<Tree> allTrees = await getAllTrees();
      return allTrees.where((tree) => tree.planterId == userId).toList();
    } catch (e) {
      print('Error getting user trees: $e');
      return [];
    }
  }
  
  // Get trees by verification status
  Future<List<Tree>> getTreesByVerificationStatus(bool isVerified) async {
    try {
      List<Tree> allTrees = await getAllTrees();
      return allTrees.where((tree) => tree.isVerified == isVerified).toList();
    } catch (e) {
      print('Error getting trees by verification status: $e');
      return [];
    }
  }
  
  // Verify a tree record
  Future<bool> verifyTree(String treeId) async {
    try {
      // For demo, we will update in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> treesJson = prefs.getStringList('trees') ?? [];
      List<Tree> trees = treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
      
      int treeIndex = trees.indexWhere((t) => t.id == treeId);
      if (treeIndex != -1) {
        // Create a new tree with updated verification status
        Tree updatedTree = Tree(
          id: trees[treeIndex].id,
          species: trees[treeIndex].species,
          location: trees[treeIndex].location,
          quantity: trees[treeIndex].quantity,
          plantingDate: trees[treeIndex].plantingDate,
          planterId: trees[treeIndex].planterId,
          photoUrl: trees[treeIndex].photoUrl,
          isVerified: true,
        );
        
        // Replace the old tree with the updated one
        trees[treeIndex] = updatedTree;
        treesJson = trees.map((t) => jsonEncode(t.toJson())).toList();
        await prefs.setStringList('trees', treesJson);
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying tree: $e');
      return false;
    }
  }
  
  // Update an existing tree
  Future<bool> updateTree(Tree tree) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> treesJson = prefs.getStringList('trees') ?? [];
      List<Tree> trees = treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
      
      int treeIndex = trees.indexWhere((t) => t.id == tree.id);
      if (treeIndex == -1) {
        return false;
      }
      
      trees[treeIndex] = tree;
      List<String> updatedTreesJson = trees.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('trees', updatedTreesJson);
      return true;
    } catch (e) {
      print('Error updating tree: $e');
      return false;
    }
  }
    // Mock data for trees
  Future<List<Tree>> _getMockTrees() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? treesJson = prefs.getStringList('trees');
    
    // If there are no trees in storage, create mock data
    if (treesJson == null || treesJson.isEmpty) {
      List<Tree> mockTrees = [
        Tree(
          id: '1',
          species: 'Acacia',
          location: 'Kisumu',
          quantity: 12,
          plantingDate: DateTime.now().subtract(const Duration(days: 7)),
          planterId: 'user1',
          isVerified: true,
        ),
        Tree(
          id: '2',
          species: 'Eucalyptus',
          location: 'Nairobi',
          quantity: 8,
          plantingDate: DateTime.now().subtract(const Duration(days: 10)),
          planterId: 'user2',
        ),
        Tree(
          id: '3',
          species: 'Grevillea',
          location: 'Mombasa',
          quantity: 15,
          plantingDate: DateTime.now().subtract(const Duration(days: 5)),
          planterId: 'user1',
        ),
      ];
      
      // Save mock data to local storage
      treesJson = mockTrees.map((tree) => jsonEncode(tree.toJson())).toList();
      await prefs.setStringList('trees', treesJson);
      return mockTrees;
    }
    
    // Parse trees from storage
    return treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
  }
}

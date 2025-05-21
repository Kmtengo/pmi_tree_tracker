// Dataverse service for handling interactions with Microsoft Dataverse
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_models.dart';

class DataverseService {
  // Dataverse API configuration - This would be stored securely in production
  final String _baseUrl = 'https://{your-instance}.api.crm.dynamics.com/api/data/v9.2';
  final String _clientId = 'your_client_id';
  final String _clientSecret = 'your_client_secret';
  final String _tenantId = 'your_tenant_id';
  
  String? _accessToken;
  DateTime? _tokenExpiry;
  
  // Get authentication token for Dataverse API
  Future<String> _getAuthToken() async {
    // Check if we already have a valid token
    if (_accessToken != null && _tokenExpiry != null && _tokenExpiry!.isAfter(DateTime.now())) {
      return _accessToken!;
    }
    
    // Request a new token
    final url = 'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'scope': '$_baseUrl/.default',
        'client_secret': _clientSecret,
        'grant_type': 'client_credentials',
      },
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return _accessToken!;
    } else {
      throw Exception('Failed to get Dataverse token: ${response.statusCode}');
    }
  }
  
  // Generic method to make authenticated HTTP requests
  Future<http.Response> _authenticatedRequest(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    final token = await _getAuthToken();
    final headers = {
      'Authorization': 'Bearer $token',
      'OData-MaxVersion': '4.0',
      'OData-Version': '4.0',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    
    final Uri uri = Uri.parse('$_baseUrl/$endpoint');
    
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: json.encode(data));
      case 'PATCH':
        return http.patch(uri, headers: headers, body: json.encode(data));
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
  }
  
  // Get trees from Dataverse
  Future<List<Tree>> getTrees() async {
    try {
      // In a real app, we would use demo data if offline or if Dataverse is not configured
      bool useDataverse = false; // Set to true in production
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (!useDataverse) {
        // Return local data instead of making API call
        List<String>? treesJson = prefs.getStringList('trees');
        if (treesJson != null && treesJson.isNotEmpty) {
          return treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
        }
        return [];
      }
      
      final response = await _authenticatedRequest('pmi_trees');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> treeData = data['value'];
        
        List<Tree> trees = treeData.map((treeJson) {
          // Map Dataverse entity fields to our Tree model
          return Tree(
            id: treeJson['pmi_treeid'] ?? '',
            species: treeJson['pmi_species'] ?? '',
            location: treeJson['pmi_location'] ?? '',
            quantity: treeJson['pmi_quantity'] ?? 0,
            plantingDate: DateTime.parse(treeJson['pmi_plantingdate']),
            planterId: treeJson['_pmi_planterid_value'] ?? '',
            photoUrl: treeJson['pmi_photourl'],
            isVerified: treeJson['pmi_isverified'] ?? false,
            teamName: treeJson['pmi_teamname'],
            latitude: treeJson['pmi_latitude'],
            longitude: treeJson['pmi_longitude'],
          );
        }).toList();
        
        // Save trees to local storage for offline access
        List<String> treesJsonString = trees.map((t) => jsonEncode(t.toJson())).toList();
        await prefs.setStringList('trees', treesJsonString);
        
        return trees;
      } else {
        throw Exception('Failed to fetch trees from Dataverse: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting trees from Dataverse: $e');
      
      // Fallback to local data if API call fails
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? treesJson = prefs.getStringList('trees');
      if (treesJson != null && treesJson.isNotEmpty) {
        return treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
      }
      
      return [];
    }
  }
  
  // Add a tree to Dataverse
  Future<bool> addTree(Tree tree) async {
    try {
      // In a real app, we would use demo data if offline or if Dataverse is not configured
      bool useDataverse = false; // Set to true in production
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (!useDataverse) {
        // Save to local storage instead of making API call
        List<String> treesJson = prefs.getStringList('trees') ?? [];
        treesJson.add(jsonEncode(tree.toJson()));
        await prefs.setStringList('trees', treesJson);
        return true;
      }
      
      // Map Tree model to Dataverse entity fields
      final treeData = {
        'pmi_species': tree.species,
        'pmi_location': tree.location,
        'pmi_quantity': tree.quantity,
        'pmi_plantingdate': tree.plantingDate.toIso8601String(),
        '_pmi_planterid_value': tree.planterId,
        'pmi_photourl': tree.photoUrl,
        'pmi_isverified': tree.isVerified,
        'pmi_teamname': tree.teamName,
        'pmi_latitude': tree.latitude,
        'pmi_longitude': tree.longitude,
      };
      
      final response = await _authenticatedRequest(
        'pmi_trees',
        method: 'POST',
        data: treeData,
      );
      
      if (response.statusCode == 201) {
        // Save to local storage for offline access
        final treesJson = prefs.getStringList('trees') ?? [];
        treesJson.add(jsonEncode(tree.toJson()));
        await prefs.setStringList('trees', treesJson);
        return true;
      } else {
        throw Exception('Failed to add tree to Dataverse: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding tree to Dataverse: $e');
      
      // Try to save locally if API call fails
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> treesJson = prefs.getStringList('trees') ?? [];
        treesJson.add(jsonEncode(tree.toJson()));
        await prefs.setStringList('trees', treesJson);
        return true;
      } catch (_) {
        return false;
      }
    }
  }
  
  // Update a tree in Dataverse
  Future<bool> updateTree(Tree tree) async {
    try {
      // In a real app, we would use demo data if offline or if Dataverse is not configured
      bool useDataverse = false; // Set to true in production
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      if (!useDataverse) {
        // Update in local storage instead of making API call
        List<String> treesJson = prefs.getStringList('trees') ?? [];
        List<Tree> trees = treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
        int index = trees.indexWhere((t) => t.id == tree.id);
        
        if (index != -1) {
          trees[index] = tree;
          List<String> updatedTreesJson = trees.map((t) => jsonEncode(t.toJson())).toList();
          await prefs.setStringList('trees', updatedTreesJson);
          return true;
        }
        return false;
      }
      
      // Map Tree model to Dataverse entity fields
      final treeData = {
        'pmi_species': tree.species,
        'pmi_location': tree.location,
        'pmi_quantity': tree.quantity,
        'pmi_plantingdate': tree.plantingDate.toIso8601String(),
        '_pmi_planterid_value': tree.planterId,
        'pmi_photourl': tree.photoUrl,
        'pmi_isverified': tree.isVerified,
        'pmi_teamname': tree.teamName,
        'pmi_latitude': tree.latitude,
        'pmi_longitude': tree.longitude,
      };
      
      final response = await _authenticatedRequest(
        'pmi_trees(${tree.id})',
        method: 'PATCH',
        data: treeData,
      );
      
      if (response.statusCode == 204) {
        // Update in local storage for offline access
        List<String> treesJson = prefs.getStringList('trees') ?? [];
        List<Tree> trees = treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
        int index = trees.indexWhere((t) => t.id == tree.id);
        
        if (index != -1) {
          trees[index] = tree;
          List<String> updatedTreesJson = trees.map((t) => jsonEncode(t.toJson())).toList();
          await prefs.setStringList('trees', updatedTreesJson);
        }
        
        return true;
      } else {
        throw Exception('Failed to update tree in Dataverse: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating tree in Dataverse: $e');
      
      // Try to update locally if API call fails
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> treesJson = prefs.getStringList('trees') ?? [];
        List<Tree> trees = treesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
        int index = trees.indexWhere((t) => t.id == tree.id);
        
        if (index != -1) {
          trees[index] = tree;
          List<String> updatedTreesJson = trees.map((t) => jsonEncode(t.toJson())).toList();
          await prefs.setStringList('trees', updatedTreesJson);
          return true;
        }
        
        return false;
      } catch (_) {
        return false;
      }
    }
  }
  
  // Synchronize local data with Dataverse when online
  Future<bool> synchronizeData() async {
    try {
      // Get local trees
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? localTreesJson = prefs.getStringList('trees');
      
      if (localTreesJson == null || localTreesJson.isEmpty) {
        return true; // Nothing to sync
      }
      
      List<Tree> localTrees = localTreesJson.map((tj) => Tree.fromJson(jsonDecode(tj))).toList();
      
      // For each local tree, check if it exists in Dataverse and update or create
      for (var tree in localTrees) {
        try {
          final checkResponse = await _authenticatedRequest('pmi_trees(${tree.id})');
          
          if (checkResponse.statusCode == 200) {
            // Tree exists, update it
            await _authenticatedRequest(
              'pmi_trees(${tree.id})',
              method: 'PATCH',
              data: {
                'pmi_species': tree.species,
                'pmi_location': tree.location,
                'pmi_quantity': tree.quantity,
                'pmi_plantingdate': tree.plantingDate.toIso8601String(),
                '_pmi_planterid_value': tree.planterId,
                'pmi_photourl': tree.photoUrl,
                'pmi_isverified': tree.isVerified,
                'pmi_teamname': tree.teamName,
                'pmi_latitude': tree.latitude,
                'pmi_longitude': tree.longitude,
              },
            );
          } else if (checkResponse.statusCode == 404) {
            // Tree doesn't exist, create it
            await _authenticatedRequest(
              'pmi_trees',
              method: 'POST',
              data: {
                'pmi_treeid': tree.id,
                'pmi_species': tree.species,
                'pmi_location': tree.location,
                'pmi_quantity': tree.quantity,
                'pmi_plantingdate': tree.plantingDate.toIso8601String(),
                '_pmi_planterid_value': tree.planterId,
                'pmi_photourl': tree.photoUrl,
                'pmi_isverified': tree.isVerified,
                'pmi_teamname': tree.teamName,
                'pmi_latitude': tree.latitude,
                'pmi_longitude': tree.longitude,
              },
            );
          }
        } catch (e) {
          print('Error synchronizing tree ${tree.id}: $e');
          // Continue with next tree
        }
      }
      
      return true;
    } catch (e) {
      print('Error synchronizing with Dataverse: $e');
      return false;
    }
  }
}

// Azure Maps service for handling map-related API calls
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tree_models.dart';

class AzureMapsService {
  // Azure Maps subscription key - This would be stored in a secure way in production
  // For demo purposes, we're including it directly in the code
  final String _subscriptionKey = 'your_azure_maps_subscription_key';
  final String _azureMapsBaseUrl = 'https://atlas.microsoft.com/';
  
  // Public getter for subscription key
  String get subscriptionKey => _subscriptionKey;
  
  // Get Azure Maps authentication token
  Future<String> getAuthenticationToken() async {
    try {
      final response = await http.get(
        Uri.parse('${_azureMapsBaseUrl}tokens/generate?api-version=1.0&subscription-key=$_subscriptionKey'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['accessToken'];
      } else {
        throw Exception('Failed to get token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to authenticate with Azure Maps: $e');
    }
  }
  
  // Get map style URL
  String getMapStyleUrl({String style = 'main'}) {
    // Azure Maps styles: main, satellite, grayscale, night, road
    return '${_azureMapsBaseUrl}map/style?api-version=1.0&style=$style&subscription-key=$_subscriptionKey';
  }
  
  // Convert trees to GeoJSON format for display on the map
  Map<String, dynamic> treesToGeoJson(List<Tree> trees) {
    List<Map<String, dynamic>> features = [];
    
    for (var tree in trees) {
      if (tree.latitude != null && tree.longitude != null) {
        features.add({
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [tree.longitude, tree.latitude]
          },
          "properties": {
            "id": tree.id,
            "species": tree.species,
            "quantity": tree.quantity,
            "plantingDate": tree.plantingDate.toIso8601String(),
            "isVerified": tree.isVerified,
            "title": "${tree.quantity} ${tree.species} trees",
            "description": "Planted on ${_formatDate(tree.plantingDate)}",
          }
        });
      }
    }
    
    return {
      "type": "FeatureCollection",
      "features": features
    };
  }
  
  // Helper function to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Search for a location using Azure Maps Search API
  Future<Map<String, dynamic>> searchLocation(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${_azureMapsBaseUrl}search/address/json?api-version=1.0&subscription-key=$_subscriptionKey&query=$query'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to search location: $e');
    }
  }
  
  // Reverse geocode coordinates to get address information
  Future<Map<String, dynamic>> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse('${_azureMapsBaseUrl}search/address/reverse/json?api-version=1.0&subscription-key=$_subscriptionKey&query=$latitude,$longitude'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to reverse geocode: $e');
    }
  }
}
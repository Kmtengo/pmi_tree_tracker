// Growth update model for tree progress tracking
class GrowthUpdate {
  final String id;
  final DateTime date;
  final String notes;
  final String? photoUrl;
  final double? heightCm;
  final String? healthStatus; // good, fair, poor
  
  GrowthUpdate({
    required this.id,
    required this.date,
    required this.notes,
    this.photoUrl,
    this.heightCm,
    this.healthStatus,
  });
  
  // Convert GrowthUpdate to map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'notes': notes,
      'photoUrl': photoUrl,
      'heightCm': heightCm,
      'healthStatus': healthStatus,
    };
  }
  
  // Create GrowthUpdate from map
  factory GrowthUpdate.fromJson(Map<String, dynamic> json) {
    return GrowthUpdate(
      id: json['id'],
      date: DateTime.parse(json['date']),
      notes: json['notes'],
      photoUrl: json['photoUrl'],
      heightCm: json['heightCm'],
      healthStatus: json['healthStatus'],
    );
  }
}

// Tree model class to represent tree planting records
class Tree {
  final String id;
  final String species;
  final String location;
  final int quantity;
  final DateTime plantingDate;
  final String planterId;
  final String? photoUrl;
  final bool isVerified;
  final String? teamName;
  final List<GrowthUpdate> growthUpdates;
  final double? latitude;
  final double? longitude;
  
  // Add a new growth update for this tree
  Tree addGrowthUpdate({
    required String notes,
    String? photoUrl,
    double? heightCm,
    String? healthStatus,
  }) {
    final newUpdate = GrowthUpdate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      notes: notes,
      photoUrl: photoUrl,
      heightCm: heightCm,
      healthStatus: healthStatus,
    );
    
    final updatedGrowthUpdates = List<GrowthUpdate>.from(growthUpdates)..add(newUpdate);
    
    return Tree(
      id: id,
      species: species,
      location: location,
      quantity: quantity,
      plantingDate: plantingDate,
      planterId: planterId,
      photoUrl: photoUrl,
      isVerified: isVerified,
      teamName: teamName,
      growthUpdates: updatedGrowthUpdates,
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  Tree({
    required this.id,
    required this.species,
    required this.location,
    required this.quantity,
    required this.plantingDate,
    required this.planterId,
    this.photoUrl,
    this.isVerified = false,
    this.teamName,
    List<GrowthUpdate>? growthUpdates,
    this.latitude,
    this.longitude,
  }) : growthUpdates = growthUpdates ?? [];
    // Convert Tree object to map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'species': species,
      'location': location,
      'quantity': quantity,
      'plantingDate': plantingDate.toIso8601String(),
      'planterId': planterId,
      'photoUrl': photoUrl,
      'isVerified': isVerified,
      'teamName': teamName,
      'growthUpdates': growthUpdates.map((update) => update.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }
  
  // Create Tree object from map
  factory Tree.fromJson(Map<String, dynamic> json) {
    List<GrowthUpdate> updates = [];
    if (json['growthUpdates'] != null) {
      updates = (json['growthUpdates'] as List)
          .map((updateJson) => GrowthUpdate.fromJson(updateJson))
          .toList();
    }
    
    return Tree(
      id: json['id'],
      species: json['species'],
      location: json['location'],
      quantity: json['quantity'],
      plantingDate: DateTime.parse(json['plantingDate']),
      planterId: json['planterId'],
      photoUrl: json['photoUrl'],
      isVerified: json['isVerified'] ?? false,
      teamName: json['teamName'],
      growthUpdates: updates,
      latitude: json['latitude'],
      longitude: json['longitude'],
    );
  }
}

// Project model to represent tree planting projects
class Project {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final int targetTrees;
  final int plantedTrees;
  
  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.targetTrees,
    required this.plantedTrees,
  });
  
  // Convert Project object to map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'status': status,
      'targetTrees': targetTrees,
      'plantedTrees': plantedTrees,
    };
  }
  
  // Create Project object from map
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'],
      targetTrees: json['targetTrees'],
      plantedTrees: json['plantedTrees'],
    );
  }
}

// User model to represent app users
class User {
  final String id;
  final String name;
  final String email;
  final String? role; // admin, coordinator, planter, verifier
  final String? region;
  final String? phone;
  final String? team;
  final int treesPlanted;
  final int projectsJoined;
  final int treesVerified;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.region,
    this.phone,
    this.team,
    this.treesPlanted = 0,
    this.projectsJoined = 0,
    this.treesVerified = 0,
  });
  
  // Convert User object to map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'region': region,
      'phone': phone,
      'team': team,
      'treesPlanted': treesPlanted,
      'projectsJoined': projectsJoined,
      'treesVerified': treesVerified,
    };
  }
  
  // Create User object from map
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      region: json['region'],
      phone: json['phone'],
      team: json['team'],
      treesPlanted: json['treesPlanted'] ?? 0,
      projectsJoined: json['projectsJoined'] ?? 0,
      treesVerified: json['treesVerified'] ?? 0,
    );
  }
}

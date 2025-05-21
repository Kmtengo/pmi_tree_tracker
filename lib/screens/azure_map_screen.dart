import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../view_models/tree_view_model.dart';
import '../models/tree_models.dart';
import '../widgets/azure_maps_widget.dart';
import '../widgets/pmi_button_styles.dart';
import 'tree_detail_screen.dart';

class AzureMapScreen extends StatefulWidget {
  const AzureMapScreen({super.key});

  @override
  State<AzureMapScreen> createState() => _AzureMapScreenState();
}

class _AzureMapScreenState extends State<AzureMapScreen> {  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _showOnlyVerified = false;
  String _selectedSpecies = '';
  String _selectedLocation = '';
  DateTime? _startDate;
  DateTime? _endDate;
  
  @override
  void initState() {
    super.initState();
    _initializeMap();
  }
  
  Future<void> _initializeMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Request location permission if not granted
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      // Load trees to display on map
      final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
      if (treeViewModel.trees.isEmpty) {
        await treeViewModel.loadTrees();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize map: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _onTreeMarkerTapped(String treeId) {
    // Find the tree from the viewModel
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    
    try {
      final tree = treeViewModel.trees.firstWhere((tree) => tree.id == treeId);
      
      // Navigate to tree detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreeDetailScreen(tree: tree),
        ),
      );
    } catch (e) {
      // If tree not found, show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Could not find tree details.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
  // Tree details are now shown in the TreeDetailScreen
  void _showFilterDialog() {
    // Current filter state
    bool showOnlyVerified = _showOnlyVerified;
    String selectedSpecies = '';
    String selectedLocation = '';
    DateTime? startDate;
    DateTime? endDate;
    
    // Get all available species and locations from trees
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    final List<String> allSpecies = treeViewModel.trees
        .map((tree) => tree.species)
        .toSet()
        .toList()
      ..sort();
    
    final List<String> allLocations = treeViewModel.trees
        .map((tree) => tree.location)
        .toSet()
        .toList()
      ..sort();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Trees'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification status filter
                    CheckboxListTile(
                      title: const Text('Show only verified trees'),
                      value: showOnlyVerified,
                      onChanged: (bool? value) {
                        setState(() {
                          showOnlyVerified = value ?? false;
                        });
                      },
                    ),
                    
                    const Divider(),
                    
                    // Species filter
                    const Text(
                      'Tree Species',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: selectedSpecies.isEmpty ? null : selectedSpecies,
                      hint: const Text('Select species'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All species'),
                        ),
                        ...allSpecies.map((species) => DropdownMenuItem<String>(
                          value: species,
                          child: Text(species),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedSpecies = value ?? '';
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Location filter
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: selectedLocation.isEmpty ? null : selectedLocation,
                      hint: const Text('Select location'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('All locations'),
                        ),
                        ...allLocations.map((location) => DropdownMenuItem<String>(
                          value: location,
                          child: Text(location),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedLocation = value ?? '';
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date range filter
                    const Text(
                      'Date Range',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              startDate == null 
                                  ? 'Start Date' 
                                  : '${startDate!.day}/${startDate!.month}/${startDate!.year}',
                              style: TextStyle(
                                color: startDate == null 
                                    ? Colors.grey 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: startDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => startDate = date);
                              }
                            },
                          ),
                        ),
                        const Text(' to '),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              endDate == null 
                                  ? 'End Date' 
                                  : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
                              style: TextStyle(
                                color: endDate == null 
                                    ? Colors.grey 
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: endDate ?? DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (date != null) {
                                setState(() => endDate = date);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    if (startDate != null && endDate != null && startDate!.isAfter(endDate!))
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Start date must be before end date',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                      selectedSpecies = '';
                      selectedLocation = '';
                      showOnlyVerified = false;
                    });                },
                  child: const Text('RESET'),                ),
                ElevatedButton(
                  onPressed: () {
                    // Check if date range is valid
                    if (startDate != null && endDate != null && startDate!.isAfter(endDate!)) {
                      return;
                    }
                    
                    // Apply filters to the parent state
                    this.setState(() {
                      _showOnlyVerified = showOnlyVerified;
                      _selectedSpecies = selectedSpecies;
                      _selectedLocation = selectedLocation;
                      _startDate = startDate;
                      _endDate = endDate;
                    });
                    
                    Navigator.pop(context);
                  },
                  style: PMIButtonStyles.primaryButton(context),
                  child: const Text('APPLY'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Tree Map'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TreeViewModel>(
        builder: (context, treeViewModel, child) {
          // If there's an error from the provider, use that
          final errorMsg = treeViewModel.error ?? _errorMessage;
          
          if (_isLoading || treeViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (errorMsg != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: $errorMsg',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeMap,
                      style: PMIButtonStyles.primaryButton(context),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
            // Filter trees based on the current filter settings
          List<Tree> filteredTrees = treeViewModel.trees;
          
          // Apply verification filter
          if (_showOnlyVerified) {
            filteredTrees = filteredTrees.where((tree) => tree.isVerified).toList();
          }
          
          // Apply species filter
          if (_selectedSpecies.isNotEmpty) {
            filteredTrees = filteredTrees.where((tree) => 
              tree.species == _selectedSpecies
            ).toList();
          }
          
          // Apply location filter
          if (_selectedLocation.isNotEmpty) {
            filteredTrees = filteredTrees.where((tree) => 
              tree.location == _selectedLocation
            ).toList();
          }
          
          // Apply date range filter
          if (_startDate != null) {
            filteredTrees = filteredTrees.where((tree) => 
              tree.plantingDate.isAfter(_startDate!) || 
              tree.plantingDate.isAtSameMomentAs(_startDate!)
            ).toList();
          }
          
          if (_endDate != null) {
            // Add one day to include the end date fully
            final endDate = _endDate!.add(const Duration(days: 1));
            filteredTrees = filteredTrees.where((tree) => 
              tree.plantingDate.isBefore(endDate)
            ).toList();
          }
              
          // Apply search query
          if (_searchQuery.isNotEmpty) {
            filteredTrees = filteredTrees.where((tree) => 
              tree.species.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              tree.location.toLowerCase().contains(_searchQuery.toLowerCase())
            ).toList();
          }
          
          return Stack(
            children: [
              // Map Widget
              AzureMapsWidget(
                trees: filteredTrees,
                onMarkerTapped: _onTreeMarkerTapped,
              ),
              
              // Search bar overlay
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.search),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search locations or species',
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: _showFilterDialog,
                          tooltip: 'Filter',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Map legend
              Positioned(
                bottom: 16,
                left: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Legend',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('Planted Trees'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
    // Not needed anymore as formatting is handled in the TreeDetailScreen
}
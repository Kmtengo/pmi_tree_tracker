import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../view_models/tree_view_model.dart';
import '../models/tree_models.dart';
import '../widgets/pmi_button_styles.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Marker> _markers = {};
  
  // Default position (Kenya - centered)
  static const CameraPosition _kenyaPosition = CameraPosition(
    target: LatLng(0.0236, 37.9062),
    zoom: 7,
  );
  
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
      
      _createMarkers(treeViewModel.trees);
      
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
  
  void _createMarkers(List<Tree> trees) {
    setState(() {
      _markers.clear();
      
      // Create a marker for each tree with valid coordinates
      for (final tree in trees) {
        if (tree.latitude != null && tree.longitude != null) {
          final markerId = MarkerId(tree.id);
          final marker = Marker(
            markerId: markerId,
            position: LatLng(tree.latitude!, tree.longitude!),
            infoWindow: InfoWindow(
              title: '${tree.quantity} ${tree.species} trees',
              snippet: 'Planted on ${_formatDate(tree.plantingDate)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          );
          
          _markers[tree.id] = marker;
        }
      }
    });
  }
  
  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Set custom map style if needed
    // controller.setMapStyle(mapStyle);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Trees'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sample filters
                CheckboxListTile(
                  title: const Text('Show all trees'),
                  value: true,
                  onChanged: (bool? value) {
                    Navigator.pop(context);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Show only verified trees'),
                  value: false,
                  onChanged: (bool? value) {
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                const Text('Tree Species'),
                CheckboxListTile(
                  title: const Text('Acacia'),
                  dense: true,
                  value: true,
                  onChanged: (bool? value) {},
                ),
                CheckboxListTile(
                  title: const Text('Eucalyptus'),
                  dense: true,
                  value: true,
                  onChanged: (bool? value) {},
                ),
              ],
            ),
          ),
          actions: [            TextButton(
              onPressed: () => Navigator.pop(context),
              style: PMIButtonStyles.textButton(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: PMIButtonStyles.primaryButton(context),
              child: const Text('APPLY'),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Google Maps View'),
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initializeMap,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // Update markers if tree data changed
          if (_markers.length != treeViewModel.trees.length) {
            _createMarkers(treeViewModel.trees);
          }
          
          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: _kenyaPosition,
                markers: _markers.values.toSet(),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                zoomControlsEnabled: false,
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
                        const Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search locations',
                              border: InputBorder.none,
                            ),
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
              // Map controls
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'location',
                      mini: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      onPressed: _goToCurrentLocation,
                      child: Icon(
                        Icons.my_location,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'refresh',
                      mini: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      onPressed: () {
                        treeViewModel.loadTrees();
                      },
                      child: Icon(
                        Icons.refresh,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
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
  
  String _formatDate(DateTime date) {
    // Simple date formatting
    return '${date.day}/${date.month}/${date.year}';
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../view_models/tree_view_model.dart';
import '../services/photo_service.dart';
import '../widgets/photo_viewer_widgets.dart';
import '../screens/custom_camera_screen.dart';

class AddTreeScreen extends StatefulWidget {
  const AddTreeScreen({super.key});

  @override
  State<AddTreeScreen> createState() => _AddTreeScreenState();
}

class _AddTreeScreenState extends State<AddTreeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _speciesController = TextEditingController();
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  
  String? _imagePath;
  bool _isGettingLocation = false;
  Position? _currentPosition;
  String? _teamName;
  
  final List<String> _teamNames = [
    'PMI Nairobi Team',
    'PMI Coastal Region',
    'PMI Western Region',
    'PMI Central Region',
    'PMI Youth Team',
  ];

  @override
  void initState() {
    super.initState();
    _teamName = _teamNames[0];
  }

  @override
  void dispose() {
    _speciesController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final BuildContext currentContext = context;
    
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permission denied';
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!mounted) return;
      
      setState(() {
        _currentPosition = position;
        _locationController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (!mounted) return;
      
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    final BuildContext currentContext = context;
    try {
      // Navigate to custom camera screen
      Navigator.of(currentContext).push(
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(
            onImageCaptured: (String path) {
              if (!mounted) return;
              setState(() {
                _imagePath = path;
              });
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }
  
  Future<void> _chooseFromGallery() async {
    final BuildContext currentContext = context;
    try {
      final path = await _photoService.pickImageFromGallery();
      if (path != null) {
        if (!mounted) return;
        setState(() {
          _imagePath = path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  void _viewImage() {
    if (_imagePath == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          imagePath: _imagePath!,
          title: 'Tree Photo Preview',
        ),
      ),
    );
  }

  Future<void> _addTree() async {
    final BuildContext currentContext = context;
    
    if (!_formKey.currentState!.validate()) return;
    
    if (_imagePath == null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please take a photo of the tree')),
      );
      return;
    }
    
    final treeViewModel = Provider.of<TreeViewModel>(currentContext, listen: false);
    final int quantity = int.parse(_quantityController.text);
    
    try {
      final success = await treeViewModel.addTree(
        species: _speciesController.text,
        location: _locationController.text,
        quantity: quantity,
        photoUrl: _imagePath,
        notes: _notesController.text,
        teamName: _teamName,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );
      
      if (!mounted) return;
      
      if (success) {
        _resetForm();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Tree planting record added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: ${treeViewModel.error ?? "Unknown error"}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _speciesController.clear();
    _locationController.clear();
    _quantityController.clear();
    _notesController.clear();
    setState(() {
      _imagePath = null;
      _currentPosition = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    // Define colors for our redesigned UI
    const Color primaryGreen = Color(0xFF38761D);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Light background
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        title: const Text(
          'Add Planting Record',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<TreeViewModel>(
        builder: (context, treeViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Tree Planting',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Tree Species
                          TextFormField(
                            controller: _speciesController,
                            decoration: const InputDecoration(
                              labelText: 'Tree Species*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.eco),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter tree species';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Location
                          TextFormField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location*',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.location_on),
                              suffixIcon: IconButton(
                                icon: _isGettingLocation
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.my_location),
                                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Quantity
                          TextFormField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Number of Trees*',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.format_list_numbered),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter number of trees';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Team selection
                          DropdownButtonFormField<String>(
                            value: _teamName,
                            decoration: const InputDecoration(
                              labelText: 'Planting Team',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.group),
                            ),
                            items: _teamNames.map((String team) {
                              return DropdownMenuItem<String>(
                                value: team,
                                child: Text(team),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _teamName = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Notes
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.note),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Photo
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tree Photo*',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Please take a clear photo of the tree planting activity',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                    onPressed: _takePhoto,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    onPressed: _chooseFromGallery,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_imagePath != null)
                            GestureDetector(
                              onTap: _viewImage,
                              child: Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(_imagePath!),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      bottom: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withAlpha(153),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.zoom_in, color: Colors.white),
                                          onPressed: _viewImage,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          
                          // Submit button
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Submit Tree Planting Record'),
                              onPressed: treeViewModel.isLoading ? null : _addTree,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              ),
                            ),
                          ),
                          
                          if (treeViewModel.isLoading)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

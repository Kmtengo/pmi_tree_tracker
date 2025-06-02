import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import '../view_models/tree_view_model.dart';
import '../services/photo_service.dart';
import '../widgets/photo_viewer_widgets.dart';
import '../screens/custom_camera_screen.dart';
import '../utils/pmi_colors.dart';

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
    'Green Warriors',
    'Eco Builders',
    'Forest Friends',
    'Tree Troopers',
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF38761D),
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tree Species Field
                  _buildLabel('Tree Species*'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _speciesController,
                    decoration: _buildInputDecoration(
                      'e.g., Oak, Mango, Pine',
                      Icons.eco,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tree species';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Location Field
                  _buildLabel('Location*'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Nairobi National Park',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      prefixIcon: const Icon(Icons.location_on, color: Color(0xFF4CAF50)),
                      suffixIcon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.my_location, color: Color(0xFF4CAF50)),
                              onPressed: _getCurrentLocation,
                            ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Number of Trees Field
                  _buildLabel('Number of Trees*'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration(
                      'e.g., 10',
                      Icons.format_list_numbered,
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
                  const SizedBox(height: 20),

                  // Planting Team Field
                  _buildLabel('Planting Team*'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _teamName,
                    decoration: _buildInputDecoration(
                      'Select Team',
                      Icons.group,
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
                  const SizedBox(height: 20),

                  // Photo Upload Section
                  _buildLabel('Tree Photo*'),
                  const SizedBox(height: 4),
                  const Text(
                    'Please take a clear photo of the tree planting activity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFBDBDBD),
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                      color: const Color(0xFFF5F5F5),
                    ),
                    child: _imagePath == null
                        ? InkWell(
                            onTap: _takePhoto,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.photo_camera,
                                    size: 48,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Upload Photo',
                                    style: TextStyle(
                                      color: Color(0xFF757575),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Camera'),
                                        onPressed: _takePhoto,
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF38761D),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        icon: const Icon(Icons.photo_library),
                                        label: const Text('Gallery'),
                                        onPressed: _chooseFromGallery,
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(0xFF38761D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            children: [
                              GestureDetector(
                                onTap: _viewImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_imagePath!),
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
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
                  const SizedBox(height: 20),

                  // Description Field
                  _buildLabel('Description (Optional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: _buildInputDecoration(
                      'Add any additional notes here...',
                      Icons.edit,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: treeViewModel.isLoading ? null : _addTree,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38761D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: treeViewModel.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Record',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF424242),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF38761D)),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF4CAF50)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

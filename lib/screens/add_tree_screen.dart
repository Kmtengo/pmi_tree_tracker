import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:ui';
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
  final _teamController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  
  String? _imagePath;  bool _isGettingLocation = false;
  Position? _currentPosition;

  @override
  void dispose() {
    _speciesController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    _teamController.dispose();
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
    
    try {      final success = await treeViewModel.addTree(
        species: _speciesController.text,
        location: _locationController.text,
        quantity: quantity,
        photoUrl: _imagePath,
        notes: _notesController.text,
        teamName: _teamController.text,
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
    _teamController.clear();
    setState(() {
      _imagePath = null;
      _currentPosition = null;
    });
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Consumer<TreeViewModel>(
        builder: (context, treeViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tree Species Field
                  _buildLabel('Tree Species*'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _speciesController,
                    hintText: 'e.g., Oak, Mango, Pine',
                    prefixIcon: const Icon(Icons.eco, color: Color(0xFF4CAF50)),
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
                  _buildInputField(
                    controller: _locationController,
                    hintText: 'e.g. Nairobi National Park',
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
                  _buildInputField(
                    controller: _quantityController,
                    hintText: 'e.g., 10',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.format_list_numbered, color: Color(0xFF4CAF50)),
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
                  const SizedBox(height: 20),                  // Planting Team Field
                  _buildLabel('Planting Team'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _teamController,
                    hintText: 'Enter team name',
                    prefixIcon: const Icon(Icons.group, color: Color(0xFF4CAF50)),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter team name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Photo Upload Section
                  _buildLabel('Tree Photo*'),
                  const SizedBox(height: 8),
                  _buildPhotoUploadArea(),
                  const SizedBox(height: 20),

                  // Description Field
                  _buildLabel('Description (Optional)'),
                  const SizedBox(height: 8),
                  _buildInputField(
                    controller: _notesController,
                    hintText: 'Add any additional notes here...',
                    maxLines: 4,
                    prefixIcon: const Icon(Icons.edit, color: Color(0xFF4CAF50)),
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Submit Record'),
                      onPressed: treeViewModel.isLoading ? null : _addTree,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38761D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Roboto',
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
        fontFamily: 'Roboto',
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF757575),
            fontSize: 14,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPhotoUploadArea() {
    return GestureDetector(
      onTap: _imagePath == null ? _showPhotoOptions : _viewImage,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFFBDBDBD),
          strokeWidth: 1,
          gap: 5.0,
        ),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imagePath == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_camera,
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Upload Photo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
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
      ),
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _chooseFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(8),
      ));

    final Path dashedPath = Path();
    final double dashWidth = 5.0;

    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}

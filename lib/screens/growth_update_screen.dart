import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tree_view_model.dart';
import '../models/tree_models.dart';
import 'dart:io';
import '../services/photo_service.dart';
import '../widgets/photo_viewer_widgets.dart';
import '../screens/custom_camera_screen.dart';
import '../widgets/leaf_pattern_background.dart';
import '../widgets/pmi_button_styles.dart';

class GrowthUpdateScreen extends StatefulWidget {
  final Tree tree;

  const GrowthUpdateScreen({super.key, required this.tree});

  @override
  State<GrowthUpdateScreen> createState() => _GrowthUpdateScreenState();
}

class _GrowthUpdateScreenState extends State<GrowthUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _heightController = TextEditingController();
  final PhotoService _photoService = PhotoService();
  
  String? _imagePath;
  String _selectedHealth = 'good';
  final List<String> _healthOptions = ['good', 'fair', 'poor'];

  @override
  void dispose() {
    _notesController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      // Navigate to custom camera screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CustomCameraScreen(
            onImageCaptured: (String path) {
              setState(() {
                _imagePath = path;
              });
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }
  
  Future<void> _chooseFromGallery() async {
    try {
      final path = await _photoService.pickImageFromGallery();
      if (path != null) {
        setState(() {
          _imagePath = path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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
          title: 'Growth Update Photo',
        ),
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo of the tree')),
      );
      return;
    }
    
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    double? heightCm;
    if (_heightController.text.isNotEmpty) {
      heightCm = double.tryParse(_heightController.text);
    }
    
    try {
      final success = await treeViewModel.addGrowthUpdate(
        treeId: widget.tree.id,
        notes: _notesController.text,
        photoUrl: _imagePath,
        heightCm: heightCm,
        healthStatus: _selectedHealth,
      );
      
      if (success) {
        // Cache the image metadata for this growth update
        await _photoService.cacheImageMetadata(
          imagePath: _imagePath!,
          treeId: widget.tree.id,
          updateId: DateTime.now().millisecondsSinceEpoch.toString(),
          timestamp: DateTime.now(),
          notes: _notesController.text,
        );
      
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Growth update added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${treeViewModel.error ?? "Unknown error"}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Add Growth Update'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: LeafPatternBackground(
        isFormPage: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tree information
                        Text(
                          'Tree: ${widget.tree.species}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Location: ${widget.tree.location}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Planted on: ${widget.tree.plantingDate.toString().substring(0, 10)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 24),

                        // Height measurement
                        TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Height (cm)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.height),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Health status
                        DropdownButtonFormField<String>(
                          value: _selectedHealth,
                          decoration: const InputDecoration(
                            labelText: 'Tree Health Status',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.health_and_safety),
                          ),
                          items: _healthOptions.map((String health) {
                            return DropdownMenuItem<String>(
                              value: health,
                              child: Text(health.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedHealth = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes*',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter notes about the growth update';
                            }
                            return null;
                          },
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
                                    'Growth Update Photo*',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Take a clear photo showing the current state of the tree',
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
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Gallery'),
                                  onPressed: _chooseFromGallery,
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
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.zoom_in, color: Colors.white),
                                        onPressed: _viewImage,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          height: 50,                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Submit Growth Update'),
                            onPressed: _submitUpdate,
                            style: PMIButtonStyles.primaryButton(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

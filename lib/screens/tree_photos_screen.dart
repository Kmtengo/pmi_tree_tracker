import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/tree_models.dart';
import '../services/photo_service.dart';
import '../widgets/photo_viewer_widgets.dart';

class TreePhotosScreen extends StatefulWidget {
  final Tree tree;
  
  const TreePhotosScreen({super.key, required this.tree});

  @override
  State<TreePhotosScreen> createState() => _TreePhotosScreenState();
}

class _TreePhotosScreenState extends State<TreePhotosScreen> {
  final PhotoService _photoService = PhotoService();
  List<Map<String, dynamic>> _treeImages = [];
  bool _isLoading = true;
  String _currentFilter = 'All';
  final List<String> _filterOptions = ['All', 'Recent', 'Oldest'];
  
  @override
  void initState() {
    super.initState();
    _loadImages();
  }
  
  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final images = await _photoService.getImagesForTree(widget.tree.id);
      
      // Sort images based on current filter
      _sortImages(images);
      
      setState(() {
        _treeImages = images;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _sortImages(List<Map<String, dynamic>> images) {
    switch (_currentFilter) {
      case 'Recent':
        images.sort((a, b) {
          DateTime timeA = DateTime.parse(a['timestamp']);
          DateTime timeB = DateTime.parse(b['timestamp']);
          return timeB.compareTo(timeA);
        });
        break;
      case 'Oldest':
        images.sort((a, b) {
          DateTime timeA = DateTime.parse(a['timestamp']);
          DateTime timeB = DateTime.parse(b['timestamp']);
          return timeA.compareTo(timeB);
        });
        break;
      default:
        // 'All' or any other - default to recent first
        images.sort((a, b) {
          DateTime timeA = DateTime.parse(a['timestamp']);
          DateTime timeB = DateTime.parse(b['timestamp']);
          return timeB.compareTo(timeA);
        });
    }
  }
  
  void _applyFilter(String filter) {
    setState(() {
      _currentFilter = filter;
      _sortImages(_treeImages);
    });
  }
  
  void _viewImage(int index) {
    if (_treeImages.isEmpty) return;
    
    List<String> imagePaths = _treeImages.map((img) => img['imagePath'] as String).toList();
    List<String> captions = _treeImages.map((img) {
      final DateTime timestamp = DateTime.parse(img['timestamp']);
      final String formattedDate = DateFormat('MMMM d, yyyy').format(timestamp);
      return formattedDate;
    }).toList();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoGalleryScreen(
          imagePaths: imagePaths,
          captions: captions,
          initialIndex: index,
          title: '${widget.tree.species} Gallery',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {    return Scaffold(      appBar: AppBar(
        title: Text('${widget.tree.species} Photos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Sort',
            onSelected: _applyFilter,
            itemBuilder: (context) {
              return _filterOptions.map((filter) {
                return PopupMenuItem<String>(
                  value: filter,
                  child: Row(
                    children: [
                      if (_currentFilter == filter)
                        Icon(
                          Icons.check,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      if (_currentFilter == filter) 
                        const SizedBox(width: 8),
                      Text(filter),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _treeImages.isEmpty
              ? _buildEmptyState()
              : _buildPhotoGrid(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No photos available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add growth updates to see photos here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _treeImages.length,
      itemBuilder: (context, index) {
        final image = _treeImages[index];
        final DateTime timestamp = DateTime.parse(image['timestamp']);
        final String formattedDate = DateFormat('MMM d, yyyy').format(timestamp);
        
        return GestureDetector(
          onTap: () => _viewImage(index),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(image['imagePath']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, size: 50),
                    );
                  },
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Growth update indicator if applicable
                if (image['updateId'] != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Growth Update',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
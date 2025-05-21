import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/tree_models.dart';
import '../view_models/tree_view_model.dart';
import '../services/photo_service.dart';
import '../widgets/photo_viewer_widgets.dart';
import 'growth_update_screen.dart';
import 'tree_photos_screen.dart';
import 'package:provider/provider.dart';

class TreeDetailScreen extends StatefulWidget {
  final Tree tree;
  
  const TreeDetailScreen({super.key, required this.tree});

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  final PhotoService _photoService = PhotoService();
  List<Map<String, dynamic>> _treeImages = [];
  bool _isLoadingImages = false;

  @override
  void initState() {
    super.initState();
    _loadTreeImages();
  }

  Future<void> _loadTreeImages() async {
    setState(() {
      _isLoadingImages = true;
    });
    
    try {
      final images = await _photoService.getImagesForTree(widget.tree.id);
      setState(() {
        _treeImages = images;
      });
    } catch (e) {
      debugPrint('Error loading tree images: $e');
    } finally {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  void _viewImage(String imagePath, {String title = 'Tree Photo'}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          imagePath: imagePath,
          title: title,
        ),
      ),
    );
  }

  void _viewAllPhotos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TreePhotosScreen(tree: widget.tree),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No photo available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, yyyy').format(date);
  }

  Widget _buildVerificationBadge(bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_circle : Icons.pending,
            size: 16,
            color: isVerified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Pending',
            style: TextStyle(
              color: isVerified ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.tree.quantity} ${widget.tree.species} Trees',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildVerificationBadge(widget.tree.isVerified),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Location', widget.tree.location),
            _buildInfoRow('Planted on', _formatDate(widget.tree.plantingDate)),
            _buildInfoRow('Team', widget.tree.teamName ?? 'Not specified'),
            if (widget.tree.latitude != null && widget.tree.longitude != null)
              _buildInfoRow(
                'Coordinates', 
                '${widget.tree.latitude!.toStringAsFixed(6)}, ${widget.tree.longitude!.toStringAsFixed(6)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthUpdates() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Growth Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Update'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GrowthUpdateScreen(tree: widget.tree),
                      ),
                    );
                    _loadTreeImages(); // Refresh images after adding update
                  },
                ),
              ],
            ),
          ),
          if (widget.tree.growthUpdates.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.tree.growthUpdates.length,
              itemBuilder: (context, index) {
                final update = widget.tree.growthUpdates[index];
                final bool isLast = index == widget.tree.growthUpdates.length - 1;
                
                return Column(
                  children: [
                    if (index == 0) const Divider(height: 1),
                    ListTile(
                      title: Text(_formatDate(update.date)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (update.heightCm != null)
                            Text('Height: ${update.heightCm!.toStringAsFixed(1)} cm'),
                          if (update.healthStatus != null)
                            Text('Health: ${update.healthStatus!.toUpperCase()}'),
                          Text(update.notes),
                        ],
                      ),
                      trailing: update.photoUrl != null
                          ? GestureDetector(
                              onTap: () => _viewImage(
                                update.photoUrl!,
                                title: 'Growth Update Photo',
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(File(update.photoUrl!)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              },
            ),
          if (widget.tree.growthUpdates.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No growth updates yet. Add one to track the tree\'s progress.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tree.species} Trees'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (widget.tree.photoUrl != null)
                  GestureDetector(
                    onTap: () => _viewImage(
                      widget.tree.photoUrl!,
                      title: 'Initial Planting Photo',
                    ),
                    child: Image.file(
                      File(widget.tree.photoUrl!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          SizedBox(
                            height: 200,
                            child: _buildImagePlaceholder(),
                          ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: _buildImagePlaceholder(),
                  ),
                
                Positioned(
                  top: 8,
                  right: 8,
                  child: ElevatedButton.icon(
                    onPressed: _viewAllPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('View All Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            _buildTreeInfo(),
            if (!_isLoadingImages && _treeImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _viewAllPhotos,
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _treeImages.length.clamp(0, 5),
                        itemBuilder: (context, index) {
                          final image = _treeImages[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => _viewImage(
                                image['imagePath'],
                                title: image['updateId'] != null
                                    ? 'Growth Update Photo'
                                    : 'Tree Photo',
                              ),
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(image['imagePath']),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            _buildGrowthUpdates(),
          ],
        ),
      ),
    );
  }
}

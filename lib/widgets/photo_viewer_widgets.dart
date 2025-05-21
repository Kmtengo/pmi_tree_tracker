import 'package:flutter/material.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoViewerScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const PhotoViewerScreen({
    super.key, 
    required this.imagePath, 
    this.title = 'Photo View',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.black,
        child: PhotoView(
          imageProvider: _getImageProvider(),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          loadingBuilder: (context, event) => Center(
            child: CircularProgressIndicator(
              value: event == null
                ? 0
                : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
            ),
          ),
        ),
      ),
    );
  }
  
  ImageProvider _getImageProvider() {
    if (imagePath.startsWith('http')) {
      return CachedNetworkImageProvider(imagePath);
    } else {
      return FileImage(File(imagePath));
    }
  }
}

class PhotoGalleryScreen extends StatefulWidget {
  final List<String> imagePaths;
  final List<String>? captions;
  final int initialIndex;
  final String title;

  const PhotoGalleryScreen({
    super.key, 
    required this.imagePaths, 
    this.captions, 
    this.initialIndex = 0,
    this.title = 'Gallery',
  });

  @override
  State<PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImageProvider(path);
    } else {
      return FileImage(File(path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement sharing functionality
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          PhotoViewGallery.builder(
            scrollPhysics: const BouncingScrollPhysics(),
            builder: (BuildContext context, int index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: _getImageProvider(widget.imagePaths[index]),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                heroAttributes: PhotoViewHeroAttributes(tag: widget.imagePaths[index]),
              );
            },
            itemCount: widget.imagePaths.length,
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                  ? 0
                  : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
              ),
            ),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            pageController: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          // Caption overlay at the bottom
          if (widget.captions != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  widget.captions![_currentIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Thumbnail Grid for multiple photos
class PhotoThumbnailGrid extends StatelessWidget {
  final List<String> imagePaths;
  final List<String>? captions;
  final Function(int) onThumbnailTap;
  final int crossAxisCount;
  final double spacing;

  const PhotoThumbnailGrid({
    super.key,
    required this.imagePaths,
    this.captions,
    required this.onThumbnailTap,
    this.crossAxisCount = 3,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => onThumbnailTap(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildThumbnail(imagePaths[index]),
              // Optional caption or overlay
              if (captions != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      captions![index],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }
}

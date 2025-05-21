import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();
  
  // Take a photo with the camera
  Future<String?> takePhoto({
    bool compress = true, 
    int quality = 80,
    int maxWidth = 1024,
    int maxHeight = 1024,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      
      if (photo == null) return null;
      
      // If compression is enabled, compress the image
      if (compress) {
        return await _compressAndSaveImage(File(photo.path));
      }
      
      // If no compression, just save the image to app directory
      return await _saveImageToAppDirectory(File(photo.path));
    } catch (e) {
      debugPrint('Error taking photo: $e');
      return null;
    }
  }
  
  // Pick image from gallery
  Future<String?> pickImageFromGallery({
    bool compress = true, 
    int quality = 80,
    int maxWidth = 1024, 
    int maxHeight = 1024,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: quality,
      );
      
      if (image == null) return null;

      // If compression is enabled, compress the image
      if (compress) {
        return await _compressAndSaveImage(File(image.path));
      }
      
      // If no compression, just save the image to app directory
      return await _saveImageToAppDirectory(File(image.path));
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }
  
  // Compress and save image to app directory
  Future<String> _compressAndSaveImage(File imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${_uuid.v4()}.jpg';
      final String targetPath = '${appDir.path}/$fileName';
      
      // Compress the image
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path, 
        targetPath,
        quality: 80,
        keepExif: true,
      );
      
      if (result != null) {
        return result.path;
      }
      return imageFile.path;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      // If compression fails, save the original
      return await _saveImageToAppDirectory(imageFile);
    }
  }
  
  // Save image to app directory
  Future<String> _saveImageToAppDirectory(File imageFile) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${_uuid.v4()}.jpg';
      final File targetFile = File('${appDir.path}/$fileName');
      
      // Copy the file to app directory
      await imageFile.copy(targetFile.path);
      
      return targetFile.path;
    } catch (e) {
      debugPrint('Error saving image: $e');
      // Return the original path if we can't save to app directory
      return imageFile.path;
    }
  }
  
  // Cache image metadata in SharedPreferences
  Future<void> cacheImageMetadata({
    required String imagePath,
    required String treeId,
    String? updateId,
    required DateTime timestamp,
    String? notes,
  }) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Get existing metadata list
      List<String> imagesJson = prefs.getStringList('tree_images') ?? [];
      
      // Add new metadata
      Map<String, dynamic> metadata = {
        'imagePath': imagePath,
        'treeId': treeId,
        'updateId': updateId,
        'timestamp': timestamp.toIso8601String(),
        'notes': notes,
      };
      
      imagesJson.add(jsonEncode(metadata));
      
      // Save back to SharedPreferences
      await prefs.setStringList('tree_images', imagesJson);
    } catch (e) {
      debugPrint('Error caching image metadata: $e');
    }
  }
  
  // Get all images for a specific tree
  Future<List<Map<String, dynamic>>> getImagesForTree(String treeId) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> imagesJson = prefs.getStringList('tree_images') ?? [];
      
      List<Map<String, dynamic>> result = [];
      
      for (String imageJson in imagesJson) {
        Map<String, dynamic> metadata = jsonDecode(imageJson);
        if (metadata['treeId'] == treeId) {
          // Verify file still exists
          File file = File(metadata['imagePath']);
          if (await file.exists()) {
            result.add(metadata);
          }
        }
      }
      
      // Sort by timestamp (newest first)
      result.sort((a, b) {
        DateTime timeA = DateTime.parse(a['timestamp']);
        DateTime timeB = DateTime.parse(b['timestamp']);
        return timeB.compareTo(timeA);
      });
      
      return result;
    } catch (e) {
      debugPrint('Error getting images for tree: $e');
      return [];
    }
  }
  
  // Get images that haven't been synced yet
  Future<List<Map<String, dynamic>>> getImagesForSync() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> imagesJson = prefs.getStringList('tree_images') ?? [];
      List<Map<String, dynamic>> result = [];
      
      for (String imageJson in imagesJson) {
        Map<String, dynamic> metadata = jsonDecode(imageJson);
        if (metadata['synced'] != true) {
          File file = File(metadata['imagePath']);
          if (await file.exists()) {
            result.add(metadata);
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting images for sync: $e');
      return [];
    }
  }

  // Mark a photo as synced
  Future<void> markPhotoAsSynced(String imagePath) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> imagesJson = prefs.getStringList('tree_images') ?? [];
      List<String> updatedImagesJson = [];
      
      for (String imageJson in imagesJson) {
        Map<String, dynamic> metadata = jsonDecode(imageJson);
        if (metadata['imagePath'] == imagePath) {
          metadata['synced'] = true;
        }
        updatedImagesJson.add(jsonEncode(metadata));
      }
      
      await prefs.setStringList('tree_images', updatedImagesJson);
    } catch (e) {
      debugPrint('Error marking photo as synced: $e');
    }
  }

  // Delete an image
  Future<bool> deleteImage(String imagePath) async {
    try {
      // Delete the file
      File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      // Remove from cached metadata
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> imagesJson = prefs.getStringList('tree_images') ?? [];
      
      List<String> updatedImagesJson = [];
      
      for (String imageJson in imagesJson) {
        Map<String, dynamic> metadata = jsonDecode(imageJson);
        if (metadata['imagePath'] != imagePath) {
          updatedImagesJson.add(imageJson);
        }
      }
      
      // Save back to SharedPreferences
      await prefs.setStringList('tree_images', updatedImagesJson);
      
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }
}

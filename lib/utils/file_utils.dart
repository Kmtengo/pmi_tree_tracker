import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class FileUtils {
  static final _uuid = Uuid();

  /// Get the application's local documents directory
  static Future<Directory> getLocalDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get the application's temporary directory
  static Future<Directory> getTempDirectory() async {
    return await getTemporaryDirectory();
  }

  /// Create a directory if it doesn't exist
  static Future<Directory> createDirectoryIfNotExists(String path) async {
    final directory = Directory(path);
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Save a file to local storage
  static Future<String> saveFile(File sourceFile, {String? customName}) async {
    final appDir = await getLocalDirectory();
    final fileName = customName ?? '${_uuid.v4()}${extension(sourceFile.path)}';
    final savedFile = await sourceFile.copy('${appDir.path}/$fileName');
    return savedFile.path;
  }

  /// Get file extension from path
  static String extension(String path) {
    return path.substring(path.lastIndexOf('.'));
  }

  /// Delete a file
  static Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Get file size in bytes
  static Future<int> getFileSize(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Create a subdirectory in the app's directory
  static Future<Directory> getSubDirectory(String name) async {
    final appDir = await getLocalDirectory();
    final subDir = Directory('${appDir.path}/$name');
    return createDirectoryIfNotExists(subDir.path);
  }

  /// Get offline storage directory for a specific feature
  static Future<Directory> getOfflineStorageDir(String feature) async {
    final appDir = await getLocalDirectory();
    final offlineDir = Directory('${appDir.path}/offline/$feature');
    return createDirectoryIfNotExists(offlineDir.path);
  }

  /// Move a file to offline storage
  static Future<String> moveToOfflineStorage(
    String sourcePath,
    String feature,
  ) async {
    final offlineDir = await getOfflineStorageDir(feature);
    final file = File(sourcePath);
    if (await file.exists()) {
      final fileName = sourcePath.split('/').last;
      final targetPath = '${offlineDir.path}/$fileName';
      await file.copy(targetPath);
      await file.delete();
      return targetPath;
    }
    throw Exception('Source file does not exist');
  }

  /// List all files in a directory
  static Future<List<FileSystemEntity>> listDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (await dir.exists()) {
      return dir.listSync();
    }
    return [];
  }

  /// Check if a file exists
  static Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  /// Read file as string
  static Future<String> readAsString(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    }
    throw Exception('File does not exist');
  }

  /// Write string to file
  static Future<void> writeAsString(String path, String contents) async {
    final file = File(path);
    await file.writeAsString(contents);
  }
}
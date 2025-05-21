import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'connectivity_service.dart';
import 'dataverse_service.dart';
import 'tree_service.dart';
import 'photo_service.dart';

class SyncService {
  final ConnectivityService _connectivityService;
  final DataverseService _dataverseService;
  final TreeService _treeService;
  final PhotoService _photoService;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  final _syncController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get syncStream => _syncController.stream;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  
  SyncService({
    required ConnectivityService connectivityService,
    required DataverseService dataverseService,
    required TreeService treeService,
    required PhotoService photoService,
  }) : _connectivityService = connectivityService,
       _dataverseService = dataverseService,
       _treeService = treeService,
       _photoService = photoService {
    _initializeSync();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_time');
    if (timestamp != null) {
      _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
  }

  Future<void> _saveLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_sync_time', DateTime.now().millisecondsSinceEpoch);
    _lastSyncTime = DateTime.now();
  }

  void _initializeSync() {
    _connectivityService.connectivityStream.listen((bool isOnline) {
      if (isOnline) {
        // Auto-sync when connection is restored
        syncData();
      }
    });
  }

  Future<bool> syncData() async {
    if (_isSyncing || !_connectivityService.isOnline) {
      return false;
    }

    _isSyncing = true;
    _syncController.add(SyncStatus(status: 'Synchronizing...', progress: 0));

    try {
      // Sync trees
      _syncController.add(SyncStatus(status: 'Synchronizing trees...', progress: 0.3));
      final treeSuccess = await _dataverseService.synchronizeData();
      if (!treeSuccess) {
        throw Exception('Failed to sync trees');
      }

      // Sync photos
      _syncController.add(SyncStatus(status: 'Synchronizing photos...', progress: 0.6));
      await _syncPhotos();

      // Update local tree data
      _syncController.add(SyncStatus(status: 'Updating local data...', progress: 0.9));
      await _treeService.getAllTrees(); // Refresh local cache

      await _saveLastSyncTime();
      _syncController.add(SyncStatus(status: 'Sync completed', progress: 1.0));
      
      return true;
    } catch (e) {
      _syncController.add(SyncStatus(status: 'Sync failed: $e', progress: 0, error: true));
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncPhotos() async {
    // Get all photos that haven't been uploaded to cloud storage
    final photos = await _photoService.getImagesForSync();
    
    for (var photo in photos) {
      try {
        // In a real app, you would upload the photo to cloud storage
        // For now, just mark it as synced in local storage
        await _photoService.markPhotoAsSynced(photo['imagePath']);
      } catch (e) {
        print('Error syncing photo: $e');
      }
    }
  }

  void dispose() {
    _syncController.close();
  }
}

class SyncStatus {
  final String status;
  final double progress;
  final bool error;

  SyncStatus({
    required this.status,
    required this.progress,
    this.error = false,
  });
}
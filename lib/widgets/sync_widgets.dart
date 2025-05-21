import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../services/connectivity_service.dart';
import 'package:intl/intl.dart';

class SyncStatusWidget extends StatelessWidget {
  final VoidCallback? onSyncPressed;
  
  const SyncStatusWidget({super.key, this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncService, ConnectivityService>(
      builder: (context, syncService, connectivity, child) {
        return StreamBuilder<SyncStatus>(
          stream: syncService.syncStream,
          builder: (context, snapshot) {
            final isSyncing = syncService.isSyncing;
            final isOnline = connectivity.isOnline;
            final lastSync = syncService.lastSyncTime;

            if (isSyncing && snapshot.hasData) {
              return _buildSyncProgressIndicator(snapshot.data!);
            }

            return ListTile(
              leading: Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.green : Colors.grey,
              ),
              title: Text(
                isOnline ? 'Connected' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                lastSync != null 
                  ? 'Last sync: ${DateFormat('MMM d, y h:mm a').format(lastSync)}'
                  : 'Never synced',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: TextButton.icon(
                icon: Icon(
                  isOnline ? Icons.sync : Icons.sync_disabled,
                  size: 20,
                ),
                label: Text(isOnline ? 'Sync Now' : 'Offline'),
                onPressed: isOnline && !isSyncing && onSyncPressed != null 
                  ? onSyncPressed 
                  : null,
                style: TextButton.styleFrom(
                  foregroundColor: isOnline ? Theme.of(context).primaryColor : Colors.grey,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSyncProgressIndicator(SyncStatus status) {
    return ListTile(
      leading: const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text(
        status.status,
        style: TextStyle(
          color: status.error ? Colors.red : null,
        ),
      ),
      subtitle: LinearProgressIndicator(
        value: status.progress,
        backgroundColor: Colors.grey[200],
      ),
    );
  }
}

class SyncButton extends StatelessWidget {
  final VoidCallback onPressed;
  
  const SyncButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SyncService, ConnectivityService>(
      builder: (context, syncService, connectivity, child) {
        return IconButton(
          icon: Stack(
            children: [
              Icon(
                connectivity.isOnline ? Icons.sync : Icons.sync_disabled,
                color: Colors.white,
              ),
              if (syncService.isSyncing)
                const Positioned.fill(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
            ],
          ),
          onPressed: !syncService.isSyncing && connectivity.isOnline 
            ? onPressed 
            : null,
          tooltip: connectivity.isOnline 
            ? (syncService.isSyncing ? 'Syncing...' : 'Sync Now')
            : 'Offline',
        );
      },
    );
  }
}
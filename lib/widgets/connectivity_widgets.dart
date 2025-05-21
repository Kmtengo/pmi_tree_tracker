import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        if (connectivity.isOnline) {
          return const SizedBox.shrink(); // Don't show anything when online
        }
        
        // Show offline banner
        return Container(
          color: Colors.red.shade800,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'You are currently offline. Changes will sync when online.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SyncStatusButton extends StatelessWidget {
  final VoidCallback onSyncPressed;
  
  const SyncStatusButton({super.key, required this.onSyncPressed});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, child) {
        return IconButton(
          icon: Icon(
            connectivity.isOnline ? Icons.sync : Icons.sync_disabled,
            color: connectivity.isOnline ? Colors.white : Colors.white.withOpacity(0.5),
          ),
          onPressed: connectivity.isOnline ? onSyncPressed : () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot sync while offline. Please connect to the internet.'),
                backgroundColor: Colors.red,
              ),
            );
          },
          tooltip: connectivity.isOnline ? 'Sync Now' : 'Offline',
        );
      },
    );
  }
}

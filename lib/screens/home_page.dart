import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tree_view_model.dart';
import '../widgets/connectivity_widgets.dart';
import '../widgets/pmi_custom_bottom_bar.dart';
import '../widgets/pmi_app_drawer.dart';
import '../services/notification_service.dart';

import 'dashboard_screen.dart';
import 'add_tree_screen.dart';
import 'azure_map_screen.dart'; // Using Azure Maps instead of Google Maps
import 'reports_screen.dart';
import 'notification_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  void _syncData() async {
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    
    try {
      // Show syncing indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronizing data...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Perform synchronization
      final success = await treeViewModel.synchronizeWithDataverse();
        if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Add a notification for successful sync
        Provider.of<NotificationService>(context, listen: false).notifyDataSynced();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${treeViewModel.error ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const AddTreeScreen(),
    const AzureMapScreen(),
    const ReportsScreen(),
  ];
  // AppBar titles for each screen
  final List<String> _appBarTitles = [
    'Dashboard',
    'Log Trees',
    'Map',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const PMIAppDrawer(),      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(_appBarTitles[_currentIndex], style: const TextStyle(color: Colors.white)),
        // Drawer icon is automatically added when a drawer is specified
        actions: [
          SyncStatusButton(
            onSyncPressed: _syncData,
          ),
          Consumer<NotificationService>(
            builder: (context, notificationService, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationService.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationService.unreadCount > 9 ? '9+' : '${notificationService.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: _screens[_currentIndex]),
        ],      ),
      bottomNavigationBar: PMICustomBottomAppBar(
        currentIndex: _currentIndex,
        onTabTapped: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

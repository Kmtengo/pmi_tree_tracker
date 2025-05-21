import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import 'tree_detail_screen.dart';
import '../view_models/tree_view_model.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'mark_all_read') {
                Provider.of<NotificationService>(context, listen: false).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              } else if (value == 'clear_all') {
                _confirmClearAll(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: Text('Clear all notifications'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationService>(
        builder: (context, notificationService, child) {
          final notifications = notificationService.notifications;
          
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You will see notifications about tree verifications,\ngrowth updates and other important events here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationTile(context, notification);
            },
          );
        },
      ),
    );
  }
  
  Widget _buildNotificationTile(BuildContext context, NotificationItem notification) {
    // Determine icon based on notification type
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case 'verification':
        icon = Icons.verified;
        iconColor = Colors.green;
        break;
      case 'growth_update':
        icon = Icons.eco;
        iconColor = Colors.green.shade700;
        break;
      case 'project':
        icon = Icons.group_work;
        iconColor = Colors.blue;
        break;
      case 'system':
        icon = Icons.info;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.grey;
    }
    
    // Format timestamp
    final formattedDate = _formatDate(notification.timestamp);
    
    return Dismissible(
      key: Key(notification.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _confirmDelete(context);
      },
      onDismissed: (direction) {
        Provider.of<NotificationService>(context, listen: false)
            .deleteNotification(notification.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: iconColor,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tileColor: notification.isRead ? null : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        onTap: () => _handleNotificationTap(context, notification),
      ),
    );
  }
  
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content: const Text('Are you sure you want to delete this notification?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    ) ?? false;
  }
  
  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Notifications'),
          content: const Text('Are you sure you want to delete all notifications? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CLEAR ALL'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (confirmed) {
      Provider.of<NotificationService>(context, listen: false).clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications cleared')),
      );
    }
  }
  
  void _handleNotificationTap(BuildContext context, NotificationItem notification) {
    // Mark notification as read
    Provider.of<NotificationService>(context, listen: false)
        .markAsRead(notification.id);
    
    // Handle navigation based on notification type
    if (notification.type == 'verification' || notification.type == 'growth_update') {
      if (notification.relatedItemId != null) {
        _navigateToTreeDetail(context, notification.relatedItemId!);
      }
    }
  }
  
  void _navigateToTreeDetail(BuildContext context, String treeId) {
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    try {
      final tree = treeViewModel.trees.firstWhere((tree) => tree.id == treeId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TreeDetailScreen(tree: tree),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find the tree details')),
      );
    }
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }
}

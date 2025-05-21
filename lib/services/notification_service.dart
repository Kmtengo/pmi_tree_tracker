import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/tree_models.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // verification, growth_update, project, system
  final String? relatedItemId; // ID of related tree, project, etc.
  
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedItemId,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'relatedItemId': relatedItemId,
    };
  }
  
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: json['type'],
      relatedItemId: json['relatedItemId'],
    );
  }
  
  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    String? type,
    String? relatedItemId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedItemId: relatedItemId ?? this.relatedItemId,
    );
  }
}

class NotificationService with ChangeNotifier {
  List<NotificationItem> _notifications = [];
  List<NotificationItem> get notifications => _notifications;
  
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  
  NotificationService() {
    _loadNotifications();
  }
  
  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getStringList('notifications') ?? [];
    
    _notifications = notificationsJson
        .map((json) => NotificationItem.fromJson(jsonDecode(json)))
        .toList();
    _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Most recent first
    
    notifyListeners();
  }
  
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = _notifications
        .map((notification) => jsonEncode(notification.toJson()))
        .toList();
    
    await prefs.setStringList('notifications', notificationsJson);
  }
  
  Future<void> addNotification({
    required String title,
    required String message,
    required String type,
    String? relatedItemId,
  }) async {
    final notification = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      relatedItemId: relatedItemId,
    );
    
    _notifications.insert(0, notification); // Add to start of the list
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  Future<void> markAllAsRead() async {
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }
  
  Future<void> clearAll() async {
    _notifications = [];
    await _saveNotifications();
    notifyListeners();
  }
  
  // Convenience methods for specific notification types
  Future<void> notifyTreeVerified(Tree tree) async {
    await addNotification(
      title: 'Tree Verified',
      message: '${tree.quantity} ${tree.species} trees in ${tree.location} have been verified.',
      type: 'verification',
      relatedItemId: tree.id,
    );
  }
  
  Future<void> notifyGrowthUpdate(Tree tree) async {
    await addNotification(
      title: 'Growth Update Added',
      message: 'A new growth update has been added for ${tree.quantity} ${tree.species} trees in ${tree.location}.',
      type: 'growth_update',
      relatedItemId: tree.id,
    );
  }
  
  Future<void> notifyDataSynced() async {
    await addNotification(
      title: 'Data Synchronized',
      message: 'Your data has been successfully synchronized with the cloud.',
      type: 'system',
    );
  }
}

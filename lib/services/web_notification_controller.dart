import 'package:flutter/material.dart';

class WebNotificationController {
  // 🔥 MULTI NOTIFICATION SYSTEM
  static ValueNotifier<List<Map<String, dynamic>>> notifications =
      ValueNotifier([]);

  // ➕ ADD NOTIFICATION
  static void trigger(Map<String, dynamic> data) {
    final newNotification = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(), // ✅ UNIQUE ID
      "status": null,
      ...data,
    };

    // 🚫 Prevent duplicate same habit notifications
final exists = notifications.value.any(
  (n) => n["habit"] == data["habit"],
);

if (exists) return;

notifications.value = [...notifications.value, newNotification];
  }

  // ❌ REMOVE USING ID (SAFE)
  static void remove(Map<String, dynamic> data) {
    notifications.value = notifications.value
        .where((n) => n["id"] != data["id"])
        .toList();
  }

  // 🧹 CLEAR ALL
  static void clearAll() {
    notifications.value = [];
  }
}
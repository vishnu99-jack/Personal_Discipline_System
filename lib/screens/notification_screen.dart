import 'package:flutter/material.dart';
import '../services/web_notification_controller.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';
import 'dart:typed_data';
import '../services/audio_helper.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Uint8List? startSoundBytes;
  Uint8List? successSoundBytes;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  // =========================
  // 🔊 LOAD AUDIO
  // =========================
  void _loadSounds() {
    final box = Hive.box('leetcode_config');
    final data = box.get('config');

    if (data != null) {
      if (data["startSoundBytes"] != null) {
        startSoundBytes =
            Uint8List.fromList(List<int>.from(data["startSoundBytes"]));
      }

      if (data["successSoundBytes"] != null) {
        successSoundBytes =
            Uint8List.fromList(List<int>.from(data["successSoundBytes"]));
      }
    }
  }

  Future<void> _playStartSound() async {
    if (startSoundBytes == null) return;

    await playSound(startSoundBytes!, _audioPlayer);
  }

  Future<void> _playSuccessSound() async {
    if (successSoundBytes == null) return;

    await playSound(successSoundBytes!, _audioPlayer);
  }

  // =========================
  // 🎯 ACTIONS
  // =========================
 void _start(Map<String, dynamic> notification) {
    

    setState(() {
      notification["status"] = "IN_PROGRESS";
      notification["startTime"] = DateTime.now();
    });
  }

  void _done(Map<String, dynamic> notification) async {
  await _playSuccessSound();

  final box = Hive.box('leetcode_sessions');
  final now = DateTime.now();

  await box.put(now.toIso8601String(), {
    "habitId": "leetcode",
    "status": "COMPLETED",
    "time": now.toIso8601String(),
  });

  // 🎉 SUCCESS POPUP
  await showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade200],
          ),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "🎉 Well Done!",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "You completed today's habit 🔥",
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  WebNotificationController.remove(notification);
}

void _snooze(Map<String, dynamic> notification) {
    WebNotificationController.remove(notification);

    Timer(const Duration(minutes: 1), () {
      WebNotificationController.trigger({
        "habit": "leetcode",
        "message": "Reminder again!",
      });
    });
  }

  void _dismiss(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (_) {
        String reason = "";

        return AlertDialog(
          title: const Text("Why skipping?"),
          content: TextField(onChanged: (v) => reason = v),
          actions: [
            TextButton(
              onPressed: () async {
                if (reason.isEmpty) return;

                final box = Hive.box('leetcode_sessions');

                await box.put("dismiss_${DateTime.now()}", {
                  "reason": reason,
                  "time": DateTime.now().toIso8601String(),
                });

                Navigator.pop(context);
                WebNotificationController.remove(notification);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // =========================
  // 🧊 GLASS TILE
  // =========================
 Widget _buildTile(Map<String, dynamic> notification) {
    final String? status = notification["status"];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade100.withOpacity(0.6),
            Colors.blue.shade50.withOpacity(0.4),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(status == "IN_PROGRESS" ? 0.4 : 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Leetcode",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 6),

          Text(notification["message"] ?? ""),

          const SizedBox(height: 12),

          if (status == null)
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _start(notification),
                  child: const Text("Start"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _snooze(notification),
                  child: const Text("Snooze"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _dismiss(notification),
                  child: const Text("Dismiss"),
                ),
              ],
            ),

          if (status == "IN_PROGRESS")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text("⏱ In Progress..."),
                const SizedBox(height: 8),

                LinearProgressIndicator(),

                const SizedBox(height: 10),

                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _done(notification),
                      child: const Text("Done"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _snooze(notification),
                      child: const Text("Snooze"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => _dismiss(notification),
                      child: const Text("Dismiss"),
                    ),
                  ],
                )
              ],
            ),
        ],
      ),
    );
  }

  // =========================
  // 🧠 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF3FF),
      appBar: AppBar(
        title: const Text("Notifications"),
        backgroundColor: Colors.blue,
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: WebNotificationController.notifications,
        builder: (context, list, _) {
          if (list.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, index) => _buildTile(list[index]),
          );
        },
      ),
    );
  }
}
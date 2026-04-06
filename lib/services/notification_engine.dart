import 'dart:async';
import 'package:hive/hive.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';
import 'web_notification_controller.dart';

class NotificationEngine {
  static Timer? _timer;
  static final Set<String> _triggeredToday = {};
  static final AudioPlayer _audioPlayer = AudioPlayer();

  // 🚀 START ENGINE
  static void start() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _checkTriggers();
    });
  }

  // 🧠 MAIN LOGIC
  static void _checkTriggers() {
    final box = Hive.box('leetcode_config');
    final data = box.get('config');

    if (data == null) return;

    final startTimeStr = data["startTime"];
    if (startTimeStr == null) return;

    final now = DateTime.now();

    final parts = startTimeStr.split(":");
    final triggerTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    final id = "${now.year}-${now.month}-${now.day}_leetcode";

    // ✅ Trigger EXACT TIME WINDOW (5 sec window)
    if (!_triggeredToday.contains(id) &&
        now.isAfter(triggerTime) &&
        now.difference(triggerTime).inSeconds <= 3) {
      
      _triggeredToday.add(id);

      // 🔥 PLAY SOUND IMMEDIATELY
      _playStartSound(data);

      // 🔔 PUSH NOTIFICATION
      WebNotificationController.trigger({
        "habit": "leetcode",
        "message": "Time to solve your daily Leetcode problem!",
      });
    }

    _resetDaily(now);
  }

  // 🔊 SOUND PLAY (ENGINE LEVEL)
  static Future<void> _playStartSound(dynamic data) async {
    try {
      final bytes = data["startSoundBytes"];
      if (bytes == null) return;

      final Uint8List sound =
          Uint8List.fromList(List<int>.from(bytes));

      final blob = html.Blob([sound]);
      final url = html.Url.createObjectUrlFromBlob(blob);

      await _audioPlayer.play(UrlSource(url));

      // ⏱ Stop after 15 sec
      Timer(const Duration(seconds: 15), () {
        _audioPlayer.stop();
      });
    } catch (e) {
      print("Engine audio error: $e");
    }
  }

  // 🔄 DAILY RESET
  static void _resetDaily(DateTime now) {
    final todayKey = "${now.year}-${now.month}-${now.day}";

    _triggeredToday.removeWhere((key) => !key.startsWith(todayKey));
  }

  // 🛑 STOP ENGINE
  static void stop() {
    _timer?.cancel();
    _audioPlayer.dispose();
  }
}
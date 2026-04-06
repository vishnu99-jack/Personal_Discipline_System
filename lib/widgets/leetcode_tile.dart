import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive/hive.dart';
import '../models/habit_session_model.dart';
import '../screens/leetcode_edit_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:personal_habit_tracker/services/web_notification_controller.dart';

class LeetcodeHabitCard extends StatefulWidget {
  const LeetcodeHabitCard({super.key});

  @override
  State<LeetcodeHabitCard> createState() => _LeetcodeHabitCardState();
}

class _LeetcodeHabitCardState extends State<LeetcodeHabitCard> {
  HabitSession? todaySession;

  Timer? timer;
  Timer? _checker;
 
  String? lastTriggeredDate;

  bool isTimeUp = false;

  Map<String, dynamic>? config;

  DateTime? startTime;
  Duration elapsed = Duration.zero;

  final Duration totalDuration = const Duration(minutes: 1);

  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<String> successQuotes = [
  "🔥 Discipline beats motivation. Keep going!",
  "🚀 One problem a day = unstoppable growth.",
  "💡 You are becoming better than yesterday.",
  "🏆 Small wins build big success.",
  "⚡ Consistency is your superpower.",
];


  @override
  void initState() {
    super.initState();
    _startTimeChecker();
    _loadConfig();
_loadTodaySession();
  }

  @override
  void dispose() {
    timer?.cancel();
    _checker?.cancel();
    super.dispose();
  }

  // CONFIG METHODS

  void _loadConfig() {
  final box = Hive.box('leetcode_config');
  final data = box.get('config');

  if (data != null) {
    config = Map<String, dynamic>.from(data);
  }
}

bool get isConfigured {
  return config != null &&
      config!["startTime"] != null &&
      config!["endTime"] != null &&
      config!["targetCount"] != null &&
      config!["startRingtone"] != null &&
      config!["successRingtone"] != null;
}

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 10),
          _buildBody(),
          const SizedBox(height: 12),
          _buildActions(),
        ],
      ),
    );
  }

  // ✅ HEADER BASED ON SESSION
  Widget _buildHeader() {
    String status = "Pending";
    Color color = Colors.orange;

    if (todaySession?.status == "COMPLETED") {
      status = "Done";
      color = Colors.green;
    } else if (todaySession?.status == "IN_PROGRESS") {
      status = "Running";
      color = Colors.blue;
    }

   return Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text("Leetcode",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Row(
      children: [
        Text(status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LeetcodeEditScreen(),
              ),
            );

            _loadConfig();
            setState(() {});
          },
        ),
      ],
    )
  ],
);
  }

  // ✅ BODY BASED ON SESSION
  Widget _buildBody() {
    if (todaySession == null) {
      final streak = _getStreak();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "💡 Solve at least 1 problem today.\nConsistency beats intensity."),
          const SizedBox(height: 8),
          Text("🔥 Current Streak: ${streak["current"]}"),
          Text("🏆 Best Streak: ${streak["best"]}"),
        ],
      );
    }

    if (todaySession!.status == "IN_PROGRESS") {
      double progress = totalDuration.inSeconds == 0
          ? 0
          : elapsed.inSeconds / totalDuration.inSeconds;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("⏱ ${_formatTime(elapsed)}"),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          if (isTimeUp)
  const Text(
    "⏰ Time's up! Keep going...",
    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
  ),
        ],
      );
    }

    if (todaySession!.status == "COMPLETED") {
      return const Text(
        "✅ Completed! Keep going 🔥",
        style: TextStyle(color: Colors.green),
      );
    }

    return const SizedBox();
  }

  // ✅ ACTIONS BASED ON SESSION
  Widget _buildActions() {
    if (!isConfigured) {
  return ElevatedButton(
    onPressed: () async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LeetcodeEditScreen(),
        ),
      );

      _loadConfig(); // reload after returning
      setState(() {});
    },
    child: const Text("Configure"),
  );
}

    if (todaySession == null) {
      return ElevatedButton(
        onPressed: _startHabit,
        child: const Text("Start"),
      );
    }

    if (todaySession!.status == "IN_PROGRESS") {
      return ElevatedButton(
        onPressed: _completeHabit,
        child: const Text("Done"),
      );
    }

    if (todaySession!.status == "COMPLETED") {
      return ElevatedButton(
        onPressed: () {
          setState(() {
            todaySession = null;
            elapsed = Duration.zero;
          });
        },
        child: const Text("Reset"),
      );
    }

    return const SizedBox();
  }

  // ✅ START HABIT
void _startHabit() async {
  startTime = DateTime.now();

  final today = startTime!.toIso8601String().split('T')[0];

  final session = HabitSession(
    id: today,
    habitId: "leetcode",
    date: today,
    startTime: startTime,
    status: "IN_PROGRESS",
  );

  final box = Hive.box('leetcode_sessions');

  await box.put(today, {
    "id": session.id,
    "habitId": session.habitId,
    "date": session.date,
    "startTime": session.startTime?.toIso8601String(),
    "status": session.status,
  });

  todaySession = session;

  timer?.cancel();

  timer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (!mounted) return;
    setState(() {
     elapsed = DateTime.now().difference(startTime!);

if (elapsed >= totalDuration) {
  isTimeUp = true;
}
    });
  });

  setState(() {});
}

  // ✅ COMPLETE HABIT
  Future<void> _completeHabit() async {
    if (startTime == null) return;

    timer?.cancel();

    final box = Hive.box('leetcode_sessions');
    final today = DateTime.now().toIso8601String().split('T')[0];

    final session = HabitSession(
      id: today,
      habitId: "leetcode",
      date: today,
      startTime: startTime,
      endTime: DateTime.now(),
      duration: elapsed.inSeconds,
      count: 1,
      status: "COMPLETED",
    );

    await box.put(today, {
      "id": session.id,
      "habitId": session.habitId,
      "date": session.date,
      "startTime": session.startTime?.toIso8601String(),
      "endTime": session.endTime?.toIso8601String(),
      "duration": session.duration,
      "count": session.count,
      "status": session.status,
    });

    await _updateStreak();

    setState(() {
      todaySession = session;
    });
    _playSuccessSound();
_showSuccessDialog();
  }

  // ✅ LOAD SESSION FROM HIVE
  void _loadTodaySession() {
    final box = Hive.box('leetcode_sessions');
    final today = DateTime.now().toIso8601String().split('T')[0];

    final data = box.get(today);

    if (data != null) {
      todaySession = HabitSession(
        id: data["id"],
        habitId: data["habitId"],
        date: data["date"],
        startTime: data["startTime"] != null
            ? DateTime.parse(data["startTime"])
            : null,
        endTime: data["endTime"] != null
            ? DateTime.parse(data["endTime"])
            : null,
        duration: data["duration"],
        count: data["count"],
        status: data["status"],
      );
    }
    if (todaySession != null && todaySession!.status == "IN_PROGRESS") {
  startTime = todaySession!.startTime;

  if (elapsed >= totalDuration) {
  isTimeUp = true;
}

  if (startTime != null) {
    elapsed = DateTime.now().difference(startTime!);

    timer?.cancel();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        elapsed = DateTime.now().difference(startTime!);
      });
    });
  }
}
  }

  void _startTimeChecker() {
  _checker = Timer.periodic(const Duration(seconds: 30), (_) {
    if (!mounted) return;
    if (!isConfigured) return;

    final now = DateTime.now();
    final today = now.toIso8601String().split('T')[0];

    final startParts = config!["startTime"].split(":");
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);

    // ✅ Trigger only once per day
    if (now.hour == startHour &&
        now.minute == startMinute &&
        lastTriggeredDate != today) {

      lastTriggeredDate = today;

      WebNotificationController.trigger({
        "habit": "leetcode",
        "message": "Time to solve your daily Leetcode problem!",
      });
    }
  });
}

// ✅ SUCCESS POP UP MESSAGE
void _showSuccessDialog() {
  final quote = (successQuotes..shuffle()).first;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("🎉 Well Done!"),
      content: Text(quote),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Continue"),
        ),
      ],
    ),
  );
}

Future<void> _playSuccessSound() async {
  try {
    await _audioPlayer.play(AssetSource('sounds/success.mp3'));
  } catch (e) {
    debugPrint("Audio error: $e");
  }
}


  // ✅ STREAK LOGIC (UNCHANGED)
  Future<void> _updateStreak() async {
    final box = Hive.box('leetcode_streak');
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    final data = box.get('streak');

    int current = 0;
    int best = 0;
    String? last;

    if (data != null) {
      current = data["currentStreak"] ?? 0;
      best = data["bestStreak"] ?? 0;
      last = data["lastCompletedDate"];
    }

    if (last != null) {
      final diff = today.difference(DateTime.parse(last)).inDays;
      current = (diff == 1) ? current + 1 : 1;
    } else {
      current = 1;
    }

    if (current > best) best = current;

    await box.put('streak', {
      "currentStreak": current,
      "bestStreak": best,
      "lastCompletedDate": todayStr,
    });
  }

  Map<String, dynamic> _getStreak() {
    final box = Hive.box('leetcode_streak');
    final data = box.get('streak');

    if (data == null) {
      return {"current": 0, "best": 0};
    }

    return {
      "current": data["currentStreak"] ?? 0,
      "best": data["bestStreak"] ?? 0,
    };
  }

  String _formatTime(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes)}:${two(d.inSeconds % 60)}";
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6)
        ],
      );
}
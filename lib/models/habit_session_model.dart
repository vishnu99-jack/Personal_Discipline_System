class HabitSession {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD

  final DateTime? startTime;
  final DateTime? endTime;

  final int? duration; // seconds

  final int? count; // for Leetcode (number of problems solved)

  final String status; 
  // COMPLETED | MISSED | DISMISSED | IN_PROGRESS

  final String? dismissReason;

  HabitSession({
    required this.id,
    required this.habitId,
    required this.date,
    this.startTime,
    this.endTime,
    this.duration,
    this.count,
    required this.status,
    this.dismissReason,
  });
}
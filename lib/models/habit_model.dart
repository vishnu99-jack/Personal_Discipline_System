class Habit {
  final String id;
  final String name;

  // COUNT, DISTANCE, STUDY, PROJECT
  final String measurementType;

  final DateTime? startTime;
  final DateTime? endTime;

  final bool isCoreHabit;

  // Flexible configuration for each habit type
  final Map<String, dynamic>? config;

  Habit({
    required this.id,
    required this.name,
    required this.measurementType,
    this.startTime,
    this.endTime,
    required this.isCoreHabit,
    this.config,
  });
}
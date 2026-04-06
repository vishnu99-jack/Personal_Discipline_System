import 'package:flutter/material.dart';
import 'core_habits_screen.dart';
import 'notification_screen.dart';
import 'dashboards_screen.dart';
import 'widget_screen.dart';
import 'package:personal_habit_tracker/services/web_notification_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: WebNotificationController.notifications,
      builder: (context, list, child) {
        // ✅ Reset when no notifications
        if (list.isEmpty) {
          _opened = false;
        }

        // ✅ Navigate when notification arrives
        if (list.isNotEmpty && !_opened) {
          _opened = true;

          Future.microtask(() {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationScreen(),
              ),
            );
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEAF3FF),
          appBar: AppBar(
            title: const Text("Personal Habit Tracker"),
            centerTitle: true,
            backgroundColor: Colors.blue,
            elevation: 0,
          ),

          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // 🔥 HEADER CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade200,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        "Welcome Boss 🚀",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Consistency builds greatness.\nStart small. Stay strong.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 🔥 NAVIGATION CARDS
                Expanded(
                  child: ListView(
                    children: [
                      _buildCard(
                        context,
                        "Core Habits",
                        Icons.track_changes,
                        const CoreHabitsScreen(),
                      ),
                      _buildCard(
                        context,
                        "Notifications",
                        Icons.notifications_active,
                        const NotificationScreen(),
                      ),
                      _buildCard(
                        context,
                        "Life Dashboards",
                        Icons.dashboard,
                        const DashboardsScreen(),
                      ),
                      _buildCard(
                        context,
                        "Home Widget",
                        Icons.widgets,
                        const WidgetScreen(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================
  // 🔷 MODERN CARD BUTTON
  // =========================
  Widget _buildCard(
      BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 12,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 26),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }
}
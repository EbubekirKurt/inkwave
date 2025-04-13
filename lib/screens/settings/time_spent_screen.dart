import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:inkwave/constants.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:async';
import 'dart:math';

class TimeSpentScreen extends StatefulWidget {
  const TimeSpentScreen({Key? key}) : super(key: key);

  @override
  State<TimeSpentScreen> createState() => _TimeSpentScreenState();
}

class _TimeSpentScreenState extends State<TimeSpentScreen> {
  int _totalMinutes = 0;
  int _todayMinutes = 0;
  double _weeklyAverage = 0;
  Map<String, int> _weeklyData = {};
  int _weeklyGoal = 210;
  int _streak = 0;

  late StreamSubscription<DocumentSnapshot> _userSubscription;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _scheduleDailyReminder();
    _listenToUserData();
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  tz.TZDateTime _nextInstanceInOneMinute() {
    final now = tz.TZDateTime.now(tz.local);
    return now.add(const Duration(minutes: 1));
  }

  void _scheduleDailyReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Günlük Hatırlatma',
      channelDescription: 'Belirli saatte bildirim gönderir',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableLights: true,
      enableVibration: true,
    );

    await _notifications.zonedSchedule(
      0,
      'Inkwave Zaman Hatırlatma',
      'Bugünkü hedefini tamamladın mı?',
      _nextInstanceInOneMinute(),
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _listenToUserData() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) async {
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      final now = DateTime.now();
      final todayKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final timeLogs = Map<String, dynamic>.from(data['time_logs'] ?? {});
      int total = data['time_spent'] ?? 0;
      int today = timeLogs[todayKey] ?? 0;

      List<int> last7Days = [];
      Map<String, int> weeklyMap = {};
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      const fixedDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

      for (int i = 0; i < 7; i++) {
        DateTime day = startOfWeek.add(Duration(days: i));
        String key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        int minutes = ((timeLogs[key] ?? 0) / 60).floor();
        last7Days.add(minutes);
        weeklyMap[fixedDays[i]] = minutes;
      }

      int goal = data['weekly_goal'] ?? 210;
      int streak = data['streak'] ?? 0;
      String lastActiveStr = data['last_active_date'] ?? '';

      const dailyGoal = 30;
      final lastActiveDate = lastActiveStr.isNotEmpty ? DateTime.tryParse(lastActiveStr) : null;
      final todayMetGoal = (today / 60).floor() >= dailyGoal;

      if (todayMetGoal && lastActiveDate != null) {
        final difference = now.difference(lastActiveDate).inDays;
        if (difference == 1) {
          streak += 1;
        } else if (difference > 1) {
          streak = 1;
        }
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'streak': streak,
          'last_active_date': todayKey,
        }, SetOptions(merge: true));
      } else if (lastActiveDate == null && todayMetGoal) {
        streak = 1;
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'streak': streak,
          'last_active_date': todayKey,
        }, SetOptions(merge: true));
      }

      setState(() {
        _totalMinutes = (total / 60).floor();
        _todayMinutes = (today / 60).floor();
        _weeklyData = weeklyMap;
        _weeklyAverage = last7Days.reduce((a, b) => a + b) / 7;
        _weeklyGoal = goal;
        _streak = streak;
      });
    });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  String _weekdayName(int weekday) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text("$label: $value", style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildGoalProgressBar({required int currentWeekMinutes, required int goalMinutes}) {
    final percentage = min(currentWeekMinutes / goalMinutes, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Haftalık Hedef", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.white24,
          color: Colors.amber,
          minHeight: 12,
        ),
        const SizedBox(height: 4),
        Text("$currentWeekMinutes / $goalMinutes dk",
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Geçirilen Süre"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGoalProgressBar(
              currentWeekMinutes: _weeklyData.values.fold(0, (a, b) => a + b),
              goalMinutes: _weeklyGoal,
            ),
            _buildInfoCard("Toplam Uygulama Süresi", "$_totalMinutes dk"),
            _buildInfoCard("Bugünkü Süre", "$_todayMinutes dk"),
            _buildInfoCard("Günlük Ortalama (7 gün)", "${_weeklyAverage.floor()} dk"),
            _buildInfoCard("🔥 Streak", "$_streak gün üst üste"),
            const SizedBox(height: 20),
            const Text("Son 7 Günlük Kullanım", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 180,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final day = value.toInt();
                          const fixedDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                          if (day < 0 || day >= fixedDays.length) return const SizedBox.shrink();
                          return Text(
                            fixedDays[day],
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          );
                        },
                        reservedSize: 20,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: List.generate(7, (index) {
                    const fixedDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                    double value = _weeklyData[fixedDays[index]]?.toDouble() ?? 0.0;
                    return BarChartGroupData(x: index, barRods: [
                      BarChartRodData(toY: value, width: 14, color: Colors.amber)
                    ]);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:inkwave/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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
  bool _isRefreshing = false;

  late StreamSubscription<DocumentSnapshot> _userSubscription;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _scheduleDailyReminder();
    _listenToUserData();
    _requestPermissions();  // İzinleri talep et
  }

  Future<void> _requestPermissions() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    _userSubscription.cancel();
    await Future.delayed(const Duration(milliseconds: 500));
    _listenToUserData();
    setState(() => _isRefreshing = false);
  }

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _notifications.initialize(initializationSettings);
  }

  tz.TZDateTime _nextInstanceInOneMinute() {
    final now = tz.TZDateTime.now(tz.local);
    return now.add(const Duration(minutes: 1));
  }

  void _scheduleDailyReminder() async {
    // Eğer izin verilmediyse, izin talep et
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Günlük Hatırlatma',
      channelDescription: 'Belirli saatte bildirim gönderir',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    try {
      await _notifications.zonedSchedule(
        0,
        'Inkwave Zaman Hatırlatma',
        'Bugünkü hedefini tamamladın mı?',
        _nextInstanceInOneMinute(),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      print("Bildirim zamanlaması hatası: $e");
    }
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

      // Bugünden geriye doğru 7 gün almak
      final daysAgo = List.generate(7, (index) => now.subtract(Duration(days: index)));
      final dayLabels = daysAgo.map((date) => DateFormat('E').format(date)).toList().reversed.toList();

      final timeLogs = Map<String, dynamic>.from(data['time_logs'] ?? {});
      int total = data['time_spent'] ?? 0;

      // Bugün için süreyi bul
      int today = timeLogs[now.toString().substring(0, 10)] ?? 0;

      List<int> last7Days = [];
      Map<String, int> weeklyMap = {};

      for (int i = 0; i < 7; i++) {
        DateTime day = daysAgo[i];
        String key = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";

        // Burada dakika cinsinden değeri alıyoruz (min: timeLogs[key] ?? 0)
        int minutes = ((timeLogs[key] ?? 0) / 60).floor(); // Dakika cinsine dönüştür
        last7Days.add(minutes);
        weeklyMap[dayLabels[i]] = minutes;
      }

      setState(() {
        _totalMinutes = (total / 60).floor();
        _todayMinutes = (today / 60).floor(); // Günlük süreyi dakika olarak göster
        _weeklyData = weeklyMap;
        _weeklyAverage = last7Days.reduce((a, b) => a + b) / 7;
        _weeklyGoal = data['weekly_goal'] ?? 210;
        _streak = data['streak'] ?? 0;
      });
    });
  }

  void _editGoalDialog() {
    final controller = TextEditingController(text: _weeklyGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Haftalık Hedefi Düzenle", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Dakika olarak hedef",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            onPressed: () async {
              int? newGoal = int.tryParse(controller.text);
              if (newGoal != null && newGoal > 0) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                    'weekly_goal': newGoal,
                  }, SetOptions(merge: true));

                  setState(() => _weeklyGoal = newGoal);
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text("Kaydet", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
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
    return GestureDetector(
      onTap: _editGoalDialog,
      child: Column(
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
      ),
    );
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_weeklyData.isEmpty) {
      return Scaffold(
        backgroundColor: AppConstants.primaryColor,
        appBar: AppBar(
          backgroundColor: AppConstants.primaryColor,
          title: const Text("Geçirilen Süre", style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),  // Yükleniyor göstergesi
      );
    }

    final maxY = ((_weeklyData.values.fold(0, max)) / 30).ceil() * 30.0;

    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        title: const Text("Geçirilen Süre", style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.black,
        color: Colors.amber,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
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
            const Text("Son 7 Günlük Kullanım",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY > 0 ? maxY : 60,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white10,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          final days = _weeklyData.keys.toList();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(days[value.toInt()],
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          if (value % 30 != 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()} dk',
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (index) {
                    final value = _weeklyData[_weeklyData.keys.toList()[index]]?.toDouble() ?? 0.0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.amber,
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: Colors.white12,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

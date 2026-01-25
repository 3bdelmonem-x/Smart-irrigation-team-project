import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'details_screen.dart'; // تأكد من إنشاء هذا الملف
import 'notifications_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("system_status");
  final DatabaseReference _notifRef = FirebaseDatabase.instance.ref("notifications");

  bool? _lastPumpStatus;
  bool? _lastRainStatus;

  void _handleNotifications(Map data) {
    bool currentPump = data['pump'] == true;
    bool currentRain = data['rain'] == true;
    bool isManual = data['manual_pump'] == true;

    String? message;

    if (_lastPumpStatus != null && _lastPumpStatus != currentPump) {
      if (currentPump) {
        message = isManual ? "تم تشغيل المضخة يدوياً" : "بدء الري التلقائي (التربة جافة)";
      } else {
        message = "تم إيقاف المضخة";
      }
    }

    if (_lastRainStatus != null && _lastRainStatus != currentRain) {
      if (currentRain) message = "تنبيه: تم اكتشاف أمطار حالياً";
    }

    if (message != null) {
      _notifRef.push().set({
        "title": "تحديث النظام",
        "body": message,
        "time": DateTime.now().toString(),
      });
    }

    _lastPumpStatus = currentPump;
    _lastRainStatus = currentRain;
  }
void _toggleManualPump(bool currentValue) {
    // نحدث المفتاحين معاً: manual_pump للتحكم، و pump للعرض الفوري
    _dbRef.update({
      "manual_pump": !currentValue,
      "pump": !currentValue, 
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text("لوحة تحكم ", style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen(onThemeChanged: widget.onThemeChanged))),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.hasError) return const Center(child: Text("حدث خطأ في الاتصال"));
          
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            _handleNotifications(data);

            int soil = int.tryParse(data['soil']?.toString() ?? '0') ?? 0;
            int water = int.tryParse(data['water']?.toString() ?? '0') ?? 0;
            String temp = data['temp']?.toString() ?? '0';
            bool rain = data['rain'] == true;
            bool pumpStatus = data['pump'] == true;
            bool manualPump = data['manual_pump'] == true;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildCircularCard("رطوبة التربة", soil, Colors.brown, isDark, Icons.grass),
                  const SizedBox(height: 20),
                  _buildLinearCard("مستوى المياه بالخزان", water, Colors.blue, isDark, Icons.waves),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildInfoBox("الحرارة", "$temp°C", Icons.thermostat, Colors.orange, isDark)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildInfoBox("حالة الجو", rain ? "ممطر" : "صافي", Icons.wb_cloudy, Colors.blueGrey, isDark)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  _buildManualControlCard(manualPump, isDark),
                  const SizedBox(height: 20),
                  _buildStatusIndicator(pumpStatus),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator(color: Colors.teal));
        },
      ),
    );
  }

  // ويدجت العداد الدائري مع الانتقال لصفحة التفاصيل
  Widget _buildCircularCard(String title, int value, Color color, bool isDark, IconData icon) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(title: title, value: "$value%", icon: icon, color: color))),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            CircularPercentIndicator(
              radius: 80.0, lineWidth: 12.0, percent: (value / 100).clamp(0.0, 1.0),
              center: Text("$value%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              progressColor: color, backgroundColor: color.withOpacity(0.1),
              circularStrokeCap: CircularStrokeCap.round, animation: true,
            ),
          ],
        ),
      ),
    );
  }

  // ويدجت العداد الخطي مع الانتقال لصفحة التفاصيل
  Widget _buildLinearCard(String title, int value, Color color, bool isDark, IconData icon) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(title: title, value: "$value%", icon: icon, color: color))),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 15),
            LinearPercentIndicator(
              lineHeight: 20.0, percent: (value / 100).clamp(0.0, 1.0),
              center: Text("$value%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              progressColor: color, backgroundColor: color.withOpacity(0.1),
              barRadius: const Radius.circular(10), animation: true,
            ),
          ],
        ),
      ),
    );
  }

  // صناديق المعلومات مع الانتقال لصفحة التفاصيل
  Widget _buildInfoBox(String title, String value, IconData icon, Color color, bool isDark) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(title: title, value: value, icon: icon, color: color))),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 35),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 14)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildManualControlCard(bool manualPump, bool isDark) {
    return Container(
      decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: SwitchListTile(
        title: Text("التحكم اليدوي", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        subtitle: Text(manualPump ? "المضخة تعمل الآن" : "المضخة متوقفة", style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
        value: manualPump, activeColor: Colors.green,
        onChanged: (val) => _toggleManualPump(manualPump),
        secondary: Icon(Icons.power_settings_new, color: manualPump ? Colors.green : Colors.grey),
      ),
    );
  }

  Widget _buildStatusIndicator(bool pumpStatus) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      decoration: BoxDecoration(color: pumpStatus ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(30), border: Border.all(color: pumpStatus ? Colors.green : Colors.red)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.water_drop, color: pumpStatus ? Colors.green : Colors.red),
          const SizedBox(width: 10),
          Text(pumpStatus ? "المضخة تعمل حالياً" : "المضخة لا تعمل", style: TextStyle(color: pumpStatus ? Colors.green[800] : Colors.red[800], fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'details_screen.dart'; // تأكد من إنشاء هذا الملف
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'lighting_control_screen.dart';
import 'report_submission_screen.dart';
import 'crop_selection_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const DashboardScreen({super.key, required this.onThemeChanged});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("system_status");
  String _userName = "مستخدم";
  final DatabaseReference _notifRef = FirebaseDatabase.instance.ref("notifications");
  final User? currentUser = FirebaseAuth.instance.currentUser;

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
  void initState() {
    super.initState();
    _fetchUserName();
  }

  void _fetchUserName() async {
    if (currentUser != null) {
      final snapshot = await FirebaseDatabase.instance.ref("User/${currentUser!.uid}/name").get();
      if (snapshot.exists) {
        setState(() {
          _userName = snapshot.value.toString();
        });
      }
    }
  }

  void _hideSystemUI() {
    // Optional: for immersive mode if needed
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      body: StreamBuilder(
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          int soil = 0;
          int water = 0;
          String temp = "0";
          bool rain = false;
          bool pumpStatus = false;
          bool manualPump = false;

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            Map data = snapshot.data!.snapshot.value as Map;
            _handleNotifications(data);
             soil = int.tryParse(data['soil']?.toString() ?? '0') ?? 0;
             water = int.tryParse(data['water']?.toString() ?? '0') ?? 0;
             temp = data['temp']?.toString() ?? '0';
             rain = data['rain'] == true;
             pumpStatus = data['pump'] == true;
             manualPump = data['manual_pump'] == true;
          }

          return CustomScrollView(
            slivers: [
              // 1. Custom App Bar acting as Header
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.teal,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade800, Colors.teal.shade400],
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "مرحباً بك،",
                                    style: GoogleFonts.almarai(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _userName,
                                    style: GoogleFonts.almarai(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white, size: 30),
                              )
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "لوحة التحكم الذكية لمزرعتك",
                            style: GoogleFonts.almarai(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const NotificationsScreen())),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: Colors.white),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => SettingsScreen(onThemeChanged: widget.onThemeChanged))),
                  ),
                ],
              ),

              // 2. Body Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("مؤشرات المزرعة", isDark),
                      const SizedBox(height: 15),
                      // Sensors Grid
                      Row(
                        children: [
                          Expanded(child: _buildSensorCard("التربة", "$soil%", Icons.grass, Colors.brown, isDark, 
                              progress: soil / 100)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSensorCard("الخزان", "$water%", Icons.water, Colors.blue, isDark, 
                              progress: water / 100)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(child: _buildSmallInfoCard("الحرارة", "$temp°C", Icons.thermostat, Colors.orange, isDark)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSmallInfoCard("الطقس", rain ? "ممطر" : "صافي", rain ? Icons.cloudy_snowing : Icons.wb_sunny, rain ? Colors.blueGrey : Colors.amber, isDark)),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      _sectionTitle("التحكم والخدمات", isDark),
                      const SizedBox(height: 15),

                      // Crop Selection Card
                      _buildActionCard("اختيار نوع الزرع وحساب الري", "جديد", Icons.eco, Colors.green, isDark, 
                          isFullWidth: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const CropSelectionScreen()))),
                      const SizedBox(height: 15),
                      
                      // Control Buttons Grid
                      Row(
                         children: [
                            Expanded(child: _buildActionCard("المضخة", manualPump ? "تشغيل" : "إيقاف", manualPump ? Icons.power : Icons.power_off, manualPump ? Colors.green : Colors.grey, isDark, 
                              onTap: () => _toggleManualPump(manualPump))),
                            const SizedBox(width: 15),
                            Expanded(child: _buildActionCard("الإضاءة", "تحكم", Icons.lightbulb, Colors.amber, isDark, 
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LightingControlScreen())))),
                         ],
                      ),
                      const SizedBox(height: 15),
                      _buildActionCard("إرسال تقرير", "نموذج", Icons.assignment_add, Colors.purple, isDark, 
                          isFullWidth: true,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const ReportSubmissionScreen()))),

                      const SizedBox(height: 30),
                      _buildStatusFooter(pumpStatus, isDark),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.almarai(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : Colors.black87,
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color, bool isDark, {double? progress}) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => DetailsScreen(title: title, value: value, icon: icon, color: color))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Icon(icon, color: color, size: 28),
                 if (progress != null)
                   CircularPercentIndicator(
                     radius: 22.0, lineWidth: 4.0, percent: progress.clamp(0.0, 1.0),
                     center: Text("${(progress * 100).toInt()}", style: TextStyle(fontSize: 10, color: isDark? Colors.white:Colors.black)),
                     progressColor: color, backgroundColor: color.withOpacity(0.1),
                   )
               ],
             ),
             const SizedBox(height: 15),
             Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey : Colors.grey[600])),
             Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallInfoCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
           Container(
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
             child: Icon(icon, color: color, size: 24),
           ),
           const SizedBox(width: 12),
           Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(title, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[600])),
               Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String status, IconData icon, Color color, bool isDark, {required VoidCallback onTap, bool isFullWidth = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisAlignment: isFullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey : Colors.grey[600])),
                Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              ],
            ),
             if (isFullWidth) ...[
               const Spacer(),
               Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400])
             ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFooter(bool pumpStatus, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: pumpStatus ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: pumpStatus ? Colors.green : Colors.red, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 12, color: pumpStatus ? Colors.green : Colors.red),
            const SizedBox(width: 10),
            Text(
              pumpStatus ? "المضخة تعمل حالياً" : "المضخة متوقفة",
              style: GoogleFonts.almarai(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: pumpStatus ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
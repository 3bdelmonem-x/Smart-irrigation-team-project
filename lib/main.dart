import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // المكتبة الجديدة
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// استيراد صفحاتك
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// تعريف محرك الإشعارات كمتغير عالمي
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// دالة معالجة الإشعارات في الخلفية (Background Handler)
// يجب أن تكون خارج أي Class وتوضع فوق الـ main
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // هنا يتم التعامل مع الإشعار القادم من سيرفر جوجل والتطبيق مغلق تماماً
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تهيئة الفايربيز
  await Firebase.initializeApp();

  // 2. إعداد إشعارات الخلفية (FCM)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. إعدادات الإشعارات المحلية (الأيقونة)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: initializationSettingsAndroid),
  );

  // 4. إنشاء قناة الإشعارات (مهم جداً لنظام أندرويد)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'smart_irrigation_alerts', 
    'تنبيهات الري والمطر',
    importance: Importance.max,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // 5. طلب إذن الإشعارات (للموبايلات الحديثة)
  await FirebaseMessaging.instance.requestPermission();

  // 6. بدء مراقبة قاعدة البيانات (للحالة والتطبيق مفتوح)
  _startGlobalMonitoring();

  runApp(const SmartIrrigationApp());
}

// دالة المراقبة المستمرة لقاعدة البيانات
void _startGlobalMonitoring() {
  DatabaseReference rootRef = FirebaseDatabase.instance.ref("system_status");

  // مراقبة حالة المضخة
  rootRef.child("pump").onValue.listen((event) {
    if (event.snapshot.value != null) {
      bool isPumpOn = event.snapshot.value as bool;
      _showLocalNotification(
        0, 
        isPumpOn ? "النظام: بدأ الري الآن 🌱" : "النظام: تم إيقاف الري 🛑",
        isPumpOn ? "المضخة تعمل حالياً لري التربة." : "تم إغلاق المضخة بنجاح.",
      );
    }
  });

  // مراقبة حالة المطر
  rootRef.child("rain").onValue.listen((event) {
    if (event.snapshot.value != null) {
      bool isRaining = event.snapshot.value as bool;
      if (isRaining) {
        _showLocalNotification(
          1, 
          "تنبيه هام: هطول أمطار 🌧️",
          "تم رصد أمطار، النظام سيقوم بتعديل استهلاك المياه تلقائياً.",
        );
      }
    }
  });
}

// دالة إظهار الإشعار المحلي
Future<void> _showLocalNotification(int id, String title, String body) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'smart_irrigation_alerts',
    'تنبيهات الري والمطر',
    importance: Importance.max,
    priority: Priority.high,
  );

  await flutterLocalNotificationsPlugin.show(
    id,
    title,
    body,
    const NotificationDetails(android: androidDetails),
  );
}

class SmartIrrigationApp extends StatefulWidget {
  const SmartIrrigationApp({super.key});

  @override
  State<SmartIrrigationApp> createState() => _SmartIrrigationAppState();
}

class _SmartIrrigationAppState extends State<SmartIrrigationApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Irrigation',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.almaraiTextTheme(ThemeData.light().textTheme),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        textTheme: GoogleFonts.almaraiTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return DashboardScreen(onThemeChanged: _toggleTheme);
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text("الإعدادات", style: GoogleFonts.almarai()),
        backgroundColor: Colors.teal,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text("الوضع الليلي", style: GoogleFonts.almarai()),
            secondary: const Icon(Icons.dark_mode),
            value: isDark,
            onChanged: (val) => widget.onThemeChanged(val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              "تسجيل الخروج",
              style: GoogleFonts.almarai(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              // تنفيذ خروج حقيقي من الفايربيز
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pop(); 
                // سيقوم الـ StreamBuilder في main.dart بإرجاعك لصفحة الـ Login تلقائياً
              }
            },
          ),
        ],
      ),
    );
  }
}
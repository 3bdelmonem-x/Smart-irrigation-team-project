import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LightingControlScreen extends StatefulWidget {
  const LightingControlScreen({super.key});

  @override
  State<LightingControlScreen> createState() => _LightingControlScreenState();
}

class _LightingControlScreenState extends State<LightingControlScreen> {
  bool isLightOn = false;

  void _toggleLight() {
    setState(() {
      isLightOn = !isLightOn;
    });
    // Here you would add logic to send the command to Firebase or hardware
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : const Color(0xFFF5F7F8),
      appBar: AppBar(
        title: Text("تحكم الإضاءة", style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb,
              size: 200,
              color: isLightOn ? Colors.yellow[700] : Colors.grey[400],
            ),
            const SizedBox(height: 50),
            Text(
              isLightOn ? "الإضاءة تعمل" : "الإضاءة مطفأة",
              style: GoogleFonts.almarai(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: _toggleLight,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: isLightOn ? Colors.red : Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: Icon(isLightOn ? Icons.power_off : Icons.power, size: 30, color: Colors.white),
              label: Text(
                isLightOn ? "إيقاف" : "تشغيل",
                style: GoogleFonts.almarai(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

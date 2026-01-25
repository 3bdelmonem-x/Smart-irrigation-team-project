import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailsScreen extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;

  const DetailsScreen({super.key, required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: color),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.almarai(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("قراءة من الحساسات", style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
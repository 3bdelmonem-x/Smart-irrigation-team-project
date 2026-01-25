import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Map<String, dynamic> _getIconAndColor(String message) {
    if (message.contains("تشغيل") || message.contains("بدء")) {
      return {"icon": Icons.play_circle_filled, "color": Colors.green};
    } else if (message.contains("إيقاف")) {
      return {"icon": Icons.stop_circle, "color": Colors.orange};
    } else if (message.contains("أمطار")) {
      return {"icon": Icons.cloudy_snowing, "color": Colors.blue};
    } else {
      return {"icon": Icons.notifications, "color": Colors.teal};
    }
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference ref = FirebaseDatabase.instance.ref("notifications");

    return Scaffold(
      appBar: AppBar(
        title: Text("سجل الإشعارات", style: GoogleFonts.almarai()),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showDeleteDialog(context, "حذف الكل؟", () => ref.remove()),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: ref.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("لا توجد إشعارات حالياً"));
          }

          // 1. استلام البيانات كـ Map
          Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

          // 2. تحويل الـ Map إلى قائمة مرتبة حسب الوقت (Time)
          List<MapEntry<dynamic, dynamic>> items = data.entries.toList();

          // 3. الفرز (Sorting) لضمان أن التاريخ الأحدث يكون في الأعلى
          items.sort((a, b) {
            String timeA = a.value['time']?.toString() ?? "";
            String timeB = b.value['time']?.toString() ?? "";
            return timeB.compareTo(timeA); // ترتيب تنازلي (الأحدث أولاً)
          });

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              String key = items[index].key;
              Map val = items[index].value;
              String body = val['body'] ?? "";
              String timeStr = val['time']?.toString() ?? "";
              String displayTime = timeStr.length >= 16 ? timeStr.substring(0, 16) : timeStr;
              
              var style = _getIconAndColor(body);

              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: style['color'].withOpacity(0.1),
                      child: Icon(style['icon'], color: style['color']),
                    ),
                    title: Text(body, style: GoogleFonts.almarai(fontSize: 14)),
                    subtitle: Text(displayTime),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => ref.child(key).remove(),
                    ),
                  ),
                  const Divider(height: 1, indent: 70),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String title, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("تأكيد", style: GoogleFonts.almarai()),
        content: Text(title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء")),
          TextButton(onPressed: () { onConfirm(); Navigator.pop(context); }, child: const Text("حذف", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}
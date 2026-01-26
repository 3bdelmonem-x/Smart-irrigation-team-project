import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  // 1. قائمة المحاصيل المتاحة (تمت إضافة المزيد)
  final List<Map<String, dynamic>> _crops = [
    {"name": "قمح", "icon": Icons.grass, "base_water": 5.0, "desc": "يحتاج ري منتظم"},
    {"name": "ذرة", "icon": Icons.bakery_dining, "base_water": 4.5, "desc": "يتحمل الجفاف قليلاً"},
    {"name": "طماطم", "icon": Icons.circle, "base_water": 3.0, "desc": "تحتاج كميات قليلة متكررة"},
    {"name": "خيار", "icon": Icons.eco, "base_water": 3.5, "desc": "يحتاج رطوبة عالية"},
    {"name": "قطن", "icon": Icons.cloud, "base_water": 6.0, "desc": "شره للمياه"},
    {"name": "بطاطس", "icon": Icons.egg, "base_water": 4.2, "desc": "تحتاج تربة رطبة دائماً"},
    {"name": "أرز", "icon": Icons.waves, "base_water": 8.0, "desc": "يحتاج غمر بالمياه"},
    {"name": "باذنجان", "icon": Icons.lens, "base_water": 4.0, "desc": "يحتاج دفء ورطوبة"},
    {"name": "فلفل", "icon": Icons.fireplace, "base_water": 3.8, "desc": "حساس لنقص المياه"},
    {"name": "مانجو", "icon": Icons.energy_savings_leaf, "base_water": 7.0, "desc": "أشجار مثمرة"},
    {"name": "زيتون", "icon": Icons.spa, "base_water": 2.5, "desc": "موفر للمياه"},
    {"name": "فواكه", "icon": Icons.apple, "base_water": 5.5, "desc": "حسب الموسم"},
  ];

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("crops_data");
  final DatabaseReference _statusRef = FirebaseDatabase.instance.ref("system_status/soil");
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  
  int _currentSoilMoisture = 0;

  @override
  void initState() {
    super.initState();
    _listenToSoilMoisture();
  }

  void _listenToSoilMoisture() {
    _statusRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentSoilMoisture = int.tryParse(event.snapshot.value.toString()) ?? 0;
        });
      }
    });
  }

  // 2. خوارزمية حساب المياه الذكية
  double _calculateSmartWater(double baseWater) {
    // إذا كانت الرطوبة عالية (> 70%)، نقلل الماء بنسبة كبيرة
    // إذا كانت متوسطة (40-70%)، نقلل الماء قليلاً
    // إذا كانت جافة (< 40%)، نعطي الكمية كاملة أو أكثر قليلاً
    if (_currentSoilMoisture > 70) {
      return baseWater * 0.3; // يحتاج 30% فقط من القيمة الأساسية
    } else if (_currentSoilMoisture > 40) {
      return baseWater * 0.7; // يحتاج 70% فقط
    } else {
      return baseWater; // الكمية كاملة
    }
  }

  // 3. حفظ البيانات في Firebase
  Future<void> _saveCropData(String cropName, double waterAmount) async {
    if (_uid == null) return;

    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    await _dbRef.child(_uid!).push().set({
      "crop_type": cropName,
      "water_amount": waterAmount.toStringAsFixed(1),
      "soil_at_time": _currentSoilMoisture,
      "date": DateTime.now().toIso8601String(),
      "day_str": todayDate,
      "status": "pending",
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تم جدولة ري $cropName بنجاح ✅", style: GoogleFonts.almarai()),
          backgroundColor: Colors.teal,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCalculationDialog(Map<String, dynamic> crop) {
    double water = _calculateSmartWater(crop['base_water']);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(crop['icon'], color: Colors.teal),
            const SizedBox(width: 10),
            Text(crop['name'], style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(crop['desc'], style: GoogleFonts.almarai(color: Colors.grey[600], fontSize: 14)),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("رطوبة التربة الحالية:", style: GoogleFonts.almarai()),
                Text("$_currentSoilMoisture%", style: GoogleFonts.almarai(fontWeight: FontWeight.bold, color: Colors.brown)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text("كمية الري المقترحة ذكياً:", style: GoogleFonts.almarai(fontSize: 14)),
                  const SizedBox(height: 5),
                  Text("${water.toStringAsFixed(1)} لتر / م²", 
                    style: GoogleFonts.almarai(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[800])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("إلغاء", style: GoogleFonts.almarai(color: Colors.red))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveCropData(crop['name'], water);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("تأكيد وحفظ", style: GoogleFonts.almarai(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text("الزراعة الذكية", style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.teal,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelStyle: GoogleFonts.almarai(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: "اختيار المحصول"),
              Tab(text: "سجل الري والتحليل"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: قائمة الاختيار المحسنة
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _crops.length,
                itemBuilder: (context, index) {
                  final crop = _crops[index];
                  return InkWell(
                    onTap: () => _showCalculationDialog(crop),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                        border: Border.all(color: Colors.teal.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                            child: Icon(crop['icon'], size: 40, color: Colors.teal),
                          ),
                          const SizedBox(height: 12),
                          Text(crop['name'], style: GoogleFonts.almarai(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 4),
                          Text("اضغط للحساب", style: GoogleFonts.almarai(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tab 2: السجل من Firebase مع تفاصيل أكثر
            if (_uid == null)
              const Center(child: Text("يرجى تسجيل الدخول"))
            else
              StreamBuilder(
                stream: _dbRef.child(_uid!).orderByChild("date").limitToLast(30).onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.teal));
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_edu, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text("لا توجد بيانات ري مسجلة", style: GoogleFonts.almarai(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  List<Map<String, dynamic>> list = [];
                  map.forEach((key, value) {
                    list.add(Map<String, dynamic>.from(value));
                  });
                  list.sort((a, b) => b['date'].compareTo(a['date']));

                  return ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
                      DateTime date = DateTime.parse(item['date']);
                      String dateStr = DateFormat('yyyy/MM/dd - hh:mm a').format(date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.water_drop, color: Colors.blue),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${item['crop_type']} • ${item['water_amount']} لتر", 
                                      style: GoogleFonts.almarai(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("رطوبة التربة حينها: ${item['soil_at_time']}%", 
                                      style: GoogleFonts.almarai(fontSize: 12, color: Colors.brown)),
                                  Text(dateStr, style: GoogleFonts.almarai(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: item['status'] == 'pending' ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                item['status'] == 'pending' ? "قيد الانتظار" : "تم الري",
                                style: GoogleFonts.almarai(fontSize: 10, fontWeight: FontWeight.bold, 
                                    color: item['status'] == 'pending' ? Colors.orange : Colors.green),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

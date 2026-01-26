import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ReportSubmissionScreen extends StatefulWidget {
  const ReportSubmissionScreen({super.key});

  @override
  State<ReportSubmissionScreen> createState() => _ReportSubmissionScreenState();
}

class _ReportSubmissionScreenState extends State<ReportSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  
  // Cloudinary Configuration
  final String _cloudName = "dyoryhqcf";
  final String _uploadPreset = "reports_preset";

  // Database Reference (Using Realtime DB to match project structure)
  final DatabaseReference _reportsRef = FirebaseDatabase.instance.ref("reports");

  /// 1. دالة اختيار الملف من الجهاز
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // السماح بكل أنواع الملفات
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
      }
    } catch (e) {
      _showSnackBar("حدث خطأ أثناء اختيار الملف: $e", Colors.red);
    }
  }

  /// 2. دالة رفع الملف إلى Cloudinary
  Future<String?> _uploadToCloudinary(PlatformFile file) async {
    if (file.path == null) return null;

    final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/auto/upload");
    
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = "reports"
      ..files.add(await http.MultipartFile.fromPath('file', file.path!));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = jsonDecode(responseString);
      return jsonMap['secure_url']; // رابط الملف المباشر
    } else {
      debugPrint("Cloudinary Error: ${response.statusCode}");
      return null;
    }
  }

  /// 3. زر الإرسال وتنفيذ العملية
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedFile == null) {
      _showSnackBar("الرجاء اختيار ملف لرفعه", Colors.orange);
      return;
    }

    setState(() => _isUploading = true);

    try {
      // أ. رفع الملف أولاً
      final  downloadUrl = await _uploadToCloudinary(_pickedFile!);

      if (downloadUrl == null) {
        throw Exception("فشل في رفع الملف إلى السيرفر");
      }

      // ب. حفظ البيانات في Firebase (Realtime Database)
      // نستخدم Realtime DB لتوحيد قاعدة البيانات في المشروع بدلاً من إضافة Firestore
      final newReportRef = _reportsRef.push();
      final user = FirebaseAuth.instance.currentUser;

      await newReportRef.set({
        "file_name": _titleController.text.isEmpty ? _pickedFile!.name : _titleController.text,
        "original_name": _pickedFile!.name,
        "file_url": downloadUrl,
        "uploaded_at": DateTime.now().toIso8601String(),
        "user_email": user?.email ?? "Anonymous",
        "status": "pending"
      });

      _showSnackBar("تم رفع التقرير بنجاح ✅", Colors.green);
      
      // تصفير الحقول
      _titleController.clear();
      setState(() {
        _pickedFile = null;
      });

    } catch (e) {
      _showSnackBar("خطأ: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.almarai()), backgroundColor: color),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar("لا يمكن فتح الرابط", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("التقارير والمستندات", style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          // === قسم الرفع ===
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("رفع مستند جديد", style: GoogleFonts.almarai(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                  const SizedBox(height: 15),
                  
                  // حقل الاسم
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "اسم التقرير (اختياري)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // منطقة اختيار الملف
                  InkWell(
                    onTap: _pickFile,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload_outlined, color: Colors.teal),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _pickedFile != null ? _pickedFile!.name : "اضغط لاختيار ملف (PDF, IMG, DOC...)",
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // زر الرفع
                  ElevatedButton(
                    onPressed: _isUploading ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isUploading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("رفع الملف وحفظ البيانات", style: GoogleFonts.almarai(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // === قائمة الملفات (StreamBuilder) ===
          Expanded(
            child: StreamBuilder(
              stream: _reportsRef.orderByChild("uploaded_at").onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasError) return const Center(child: Text("خطأ في تحميل البيانات"));
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return Center(child: Text("لا توجد تقارير مرفوعة حتى الآن", style: GoogleFonts.almarai(color: Colors.grey)));
                }

                // تحويل البيانات من Map إلى List
                Map<dynamic, dynamic> map = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                List<Map<String, dynamic>> items = [];
                map.forEach((key, value) {
                  items.add({
                    "key": key,
                    ...Map<String, dynamic>.from(value)
                  });
                });

                // ترتيب عكسي (الأحدث أولاً)
                items.sort((a, b) => b['uploaded_at'].compareTo(a['uploaded_at']));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.insert_drive_file, color: Colors.white),
                        ),
                        title: Text(item['file_name'] ?? "ملف بدون عنوان", style: GoogleFonts.almarai(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${item['original_name']}\n${item['uploaded_at'].substring(0, 10)}", 
                          style: GoogleFonts.almarai(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, color: Colors.blue),
                          onPressed: () => _launchURL(item['file_url']),
                        ),
                        onTap: () => _launchURL(item['file_url']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

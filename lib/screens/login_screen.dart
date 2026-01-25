import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool isLogin = true;

  // دالة تحويل أخطاء الفايربيز لعربي
  String getArabicError(String code) {
    switch (code) {
      case 'weak-password': return 'كلمة المرور ضعيفة جداً (أقل من 6 أرقام).';
      case 'email-already-in-use': return 'هذا الإيميل مسجل مسبقاً.';
      case 'user-not-found': return 'لا يوجد حساب بهذا الإيميل.';
      case 'wrong-password': return 'كلمة المرور غير صحيحة.';
      case 'invalid-email': return 'صيغة البريد الإلكتروني غير صحيحة.';
      default: return 'حدث خطأ، حاول مرة أخرى.';
    }
  }

  Future<void> _submit() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text.trim());
      } else {
        UserCredential res = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _email.text.trim(), password: _password.text.trim());
        await FirebaseDatabase.instance.ref("User/${res.user!.uid}").set({
          "name": _name.text.trim(),
          "email": _email.text.trim(),
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getArabicError(e.code), style: GoogleFonts.almarai())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.eco, size: 80, color: Colors.teal),
                const SizedBox(height: 20),
                Text(isLogin ? "تسجيل الدخول" : "إنشاء حساب جديد", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),
                if (!isLogin) TextField(controller: _name, decoration: const InputDecoration(labelText: "الاسم الكامل", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _email, decoration: const InputDecoration(labelText: "البريد الإلكتروني", border: OutlineInputBorder())),
                const SizedBox(height: 15),
                TextField(controller: _password, decoration: const InputDecoration(labelText: "كلمة السر", border: OutlineInputBorder()), obscureText: true),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.teal),
                  child: Text(isLogin ? "دخول" : "تسجيل", style: const TextStyle(color: Colors.white)),
                ),
                TextButton(onPressed: () => setState(() => isLogin = !isLogin), child: Text(isLogin ? "ليس لديك حساب؟ سجل هنا" : "لديك حساب؟ سجل دخول"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
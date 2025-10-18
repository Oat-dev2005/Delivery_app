// import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/pages/customer/homepage_customer.dart';
import 'package:delivery_app/pages/rider/homepage_rider.dart';
import 'package:flutter/material.dart';

import 'register.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneCtl = TextEditingController();
    final passCtl = TextEditingController();

    Future<void> login() async {
      try {
        var db = FirebaseFirestore.instance;

        // 🔍 ค้นหาจาก Firestore ว่ามี user ที่ phone + password ตรงกันหรือไม่
        var query = await db
            .collection("Users")
            .where("phone", isEqualTo: phoneCtl.text)
            .where("password", isEqualTo: passCtl.text)
            .get();

        if (query.docs.isNotEmpty) {
          // ✅ พบผู้ใช้
          var user = query.docs.first.data();
          String role = user["role"] ?? "customer";
          String userId = query.docs.first.id; // เก็บ documentId

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("เข้าสู่ระบบสำเร็จ ✅")));

          if (role == "customer") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomepageCustomer(
                  phone: phoneCtl.text, // 👉 ส่งเบอร์โทร
                  role: role, // 👉 ส่ง role
                ),
              ),
            );
          } else if (role == "rider") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomepageRider(
                  phone: phoneCtl.text, // 👉 ส่งเบอร์โทร
                  role: role, // 👉 ส่ง role
                ),
              ),
            );
          }
        } else {
          // ❌ ไม่เจอข้อมูล
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("เบอร์โทรหรือรหัสผ่านไม่ถูกต้อง ❌")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด ❌: $e")));
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              color: const Color(0xFFFF8C42),
              child: const Center(
                child: Text(
                  "เข้าสู่ระบบ",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Image.asset(
              'assets/images/express_delivery.png',
              width: 350,
              height: 350,
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: TextField(
                controller: phoneCtl,
                decoration: InputDecoration(
                  hintText: 'กรอกเบอร์โทร',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8C42),
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8C42),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: TextField(
                controller: passCtl,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'กรอกรหัสผ่าน',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 20,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8C42),
                      width: 3,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF8C42),
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: login,
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),

            // Padding(
            //   padding: const EdgeInsets.all(0),
            //   child: Align(
            //     alignment: Alignment.center,
            //     child: TextButton(
            //       onPressed: () {},
            //       child: const Text(
            //         'ลืมรหัสผ่าน',
            //         style: TextStyle(color: Color(0xFF4AA3A1)),
            //       ),
            //     ),
            //   ),
            // ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("หากยังไม่มีข้อมูลยังไม่เป็นสมาชิก "),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterPage(),
                      ),
                    );
                  },
                  child: Text(
                    "ลงทะเบียน",
                    style: TextStyle(
                      color: Color(0xFFFF8C42),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

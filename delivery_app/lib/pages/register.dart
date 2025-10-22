import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final fullnameCtl = TextEditingController();
  final phoneCtl = TextEditingController();
  final passCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final vehicleCtl = TextEditingController();

  String selectedRole = "customer"; // default
  String imageBase64 = '';
  String riderImageBase64 = '';
  String vehicleImageBase64 = '';

  Future<void> registerUser() async {
    try {
      var db = FirebaseFirestore.instance;

      var query = await db
          .collection("Users")
          .where("phone", isEqualTo: phoneCtl.text)
          .get();

      if (query.docs.isNotEmpty) {
        // ถ้ามีข้อมูลอยู่แล้ว → ห้ามสมัครซ้ำ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เบอร์โทรนี้ถูกใช้งานแล้ว ❌")),
        );
        return;
      }

      // เตรียม data ตาม role
      Map<String, dynamic> data = {
        "fullname": fullnameCtl.text,
        "phone": phoneCtl.text,
        "password": passCtl
            .text, // ❗ ไม่ควรเก็บ password แบบ text ควรเข้ารหัส แต่เดียวค่อยทำ
        "role": selectedRole,
      };

      if (selectedRole == "customer") {
        data.addAll({"address": addressCtl.text, "image": imageBase64});
      } else if (selectedRole == "rider") {
        data.addAll({
          "vehicleNumber": vehicleCtl.text,
          "riderImage": riderImageBase64,
          "vehicleImage": vehicleImageBase64,
        });
      }

      // บันทึกข้อมูลลง Firestore (collection: Users)
      var docRef = db.collection("Users").doc();
      await docRef.set(data);

      String userId = docRef.id;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("สมัครสมาชิกสำเร็จ ✅")));

      // 🔹 ส่ง id ไปเก็บ (เพื่อส่งต่อไปหน้าอื่น)
      Navigator.pop(context, userId);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด ❌: $e")));
    }
  }

  Future<void> pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Img = base64Encode(bytes);

      setState(() {
        if (type == "customer") {
          imageBase64 = base64Img;
        } else if (type == "riderImage") {
          riderImageBase64 = base64Img;
        } else if (type == "vehicleImage") {
          vehicleImageBase64 = base64Img;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ส่วนหัว
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: const BoxDecoration(color: const Color(0xFFFF8C42)),
              child: const Center(
                child: Text(
                  "ลงทะเบียน",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: InputDecoration(
                      labelText: "ตัวเลือก : ลูกค้า/ไรเดอร์",
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "customer",
                        child: Text("Customer"),
                      ),
                      DropdownMenuItem(value: "rider", child: Text("Rider")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ชื่อ-สกุล
                  TextField(
                    controller: fullnameCtl,
                    decoration: InputDecoration(
                      hintText: "ชื่อ-สกุล",
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // เบอร์โทร
                  TextField(
                    controller: phoneCtl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "เบอร์โทร",
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // field เฉพาะสำหรับ customer
                  if (selectedRole == "customer") ...[
                    TextField(
                      controller: addressCtl,
                      // keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "ที่อยู่",
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
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () => pickImage("customer"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xFFFF8C42),
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image, color: Color(0xFFFF8C42)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                imageBase64.isEmpty
                                    ? "เลือกรูปโปรไฟล์"
                                    : "อัปโหลดรูป(โปรไฟล์ลูกค้า)แล้ว",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // field เฉพาะสำหรับ Rider
                  if (selectedRole == "rider") ...[
                    TextField(
                      controller: vehicleCtl,
                      decoration: InputDecoration(
                        hintText: "ยานพาหนะ (เช่น มอเตอร์ไซค์)",
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
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // รูปบัตร/รูปโปรไฟล์ Rider
                    GestureDetector(
                      onTap: () => pickImage("riderImage"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xFFFF8C42),
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person, color: Color(0xFFFF8C42)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                riderImageBase64.isEmpty
                                    ? "เลือกรูปไรเดอร์"
                                    : "อัปโหลดรูป(ไรเดอร์)แล้ว",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // รูปรถ/ทะเบียนรถ
                    GestureDetector(
                      onTap: () => pickImage("vehicleImage"),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.white,
                          border: Border.all(
                            color: Color(0xFFFF8C42),
                            width: 3,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_bike,
                              color: Color(0xFFFF8C42),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                vehicleImageBase64.isEmpty
                                    ? "เลือกรูปรถ/ทะเบียนรถ"
                                    : "อัปโหลดรูป(รถ/ทะเบียนรถ)แล้ว",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // รหัสผ่าน
                  TextField(
                    controller: passCtl,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "รหัสผ่าน",
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
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C42),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "สมัครสมาชิก",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("หากคุณเป็นสมาชิก "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          "เข้าสู่ระบบ",
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
          ],
        ),
      ),
    );
  }
}

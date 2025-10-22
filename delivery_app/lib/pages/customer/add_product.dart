import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductPage extends StatefulWidget {
  final String userId;

  const AddProductPage({super.key, required this.userId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final productNameCtl = TextEditingController();
  final receiverNameCtl = TextEditingController();
  final receiverPhoneCtl = TextEditingController();
  String productImageBase64 = '';

  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        productImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> addProduct() async {
    // เช็คว่ากรอกข้อมูลครบหรือเปล่า
    if (productNameCtl.text.isEmpty ||
        receiverNameCtl.text.isEmpty ||
        receiverPhoneCtl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง ⚠️")),
      );
      return;
    }

    try {
      // ✅ บันทึกข้อมูลสินค้า พร้อม ownerId
      final receiverQuery = await db
          .collection("Users") // 🔹 ชื่อ collection ผู้ใช้
          .where("fullname", isEqualTo: receiverNameCtl.text.trim())
          .where("phone", isEqualTo: receiverPhoneCtl.text.trim())
          .get();

      if (receiverQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ไม่พบข้อมูลผู้รับในระบบ ❌"),
            backgroundColor: Colors.redAccent,
          ),
        );
        return; // ❌ ยกเลิกการเพิ่มสินค้า
      }

      await db.collection("Products").add({
        "senderId": widget.userId, // ใช้ userId ที่ส่งมาจากหน้าอื่น
        "productName": productNameCtl.text,
        "receiverName": receiverNameCtl.text,
        "receiverPhone": receiverPhoneCtl.text,
        "productImage": productImageBase64,
        "status": "รอไรเดอร์มารับสินค้า",
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เพิ่มสินค้าเรียบร้อย ✅")));

      // ล้างฟอร์ม
      productNameCtl.clear();
      receiverNameCtl.clear();
      receiverPhoneCtl.clear();
      setState(() {
        productImageBase64 = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  @override
  void dispose() {
    productNameCtl.dispose();
    receiverNameCtl.dispose();
    receiverPhoneCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มสินค้าใหม่"),
        backgroundColor: const Color(0xFFFF8C42),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ชื่อสินค้าที่ต้องการส่ง",
              style: TextStyle(fontSize: 16),
            ),
            TextField(
              controller: productNameCtl,
              decoration: const InputDecoration(
                hintText: "ใส่ชื่อสินค้า",
                filled: true,
              ),
            ),
            const SizedBox(height: 15),

            const Text("ชื่อผู้รับสินค้า", style: TextStyle(fontSize: 16)),
            TextField(
              controller: receiverNameCtl,
              decoration: const InputDecoration(
                hintText: "ใส่ชื่อผู้รับสินค้า",
                filled: true,
              ),
            ),
            const SizedBox(height: 15),

            const Text("เบอร์ผู้รับสินค้า", style: TextStyle(fontSize: 16)),
            TextField(
              controller: receiverPhoneCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "ใส่เบอร์ผู้รับสินค้า",
                filled: true,
              ),
            ),

            const SizedBox(height: 15),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.white,
                  border: Border.all(color: Color(0xFFFF8C42), width: 3),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Color(0xFFFF8C42)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        productImageBase64.isEmpty
                            ? "เลือกรูปสินค้า"
                            : "อัปโหลดรูปสินค้าแล้ว",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: addProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "บันทึกข้อมูลการส่งสินค้า",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

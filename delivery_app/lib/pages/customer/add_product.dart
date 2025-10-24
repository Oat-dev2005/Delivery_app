import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AddProductPage extends StatefulWidget {
  final String userId;

  const AddProductPage({super.key, required this.userId});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final productNameCtl = TextEditingController();
  final searchPhoneCtl = TextEditingController();
  String productImageBase64 = '';

  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  Map<String, dynamic>? senderInfo;
  Map<String, dynamic>? selectedUser;
  Map<String, double>? selectedLocation;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchSenderInfo();
  }

  /// 🔹 ดึงเฉพาะผู้ใช้ role = customer
  Future<void> fetchUsers() async {
    final snapshot = await db
        .collection("Users")
        .where('role', isEqualTo: 'customer')
        .get();

    final allUsers = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    setState(() {
      users = allUsers.cast<Map<String, dynamic>>();
    });
  }

  /// 🔹 ดึงข้อมูลผู้ส่ง
  Future<void> fetchSenderInfo() async {
    try {
      final snapshot = await db.collection("Users").doc(widget.userId).get();
      if (snapshot.exists) {
        setState(() {
          senderInfo = snapshot.data();
        });
      }
    } catch (e) {
      print("Error loading sender info: $e");
    }
  }

  /// 🔹 กรองผู้ใช้จากหมายเลขโทรศัพท์
  void filterUsers(String phone) {
    setState(() {
      filteredUsers = users.where((user) {
        final userPhone = user['phone']?.toString() ?? '';
        return userPhone.contains(phone) && user['role'] == 'customer';
      }).toList();
    });
  }

  /// 📸 เลือกรูปได้ทั้งจากกล้องและแกลเลอรี่
  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text("ถ่ายภาพใหม่"),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text("เลือกรูปจากแกลเลอรี่"),
                onTap: () async {
                  Navigator.pop(context);
                  await _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🧩 ฟังก์ชันย่อย สำหรับเปิดกล้องหรือแกลเลอรี่
  Future<void> _getImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);

    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        productImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> addProduct() async {
    if (productNameCtl.text.isEmpty ||
        selectedUser == null ||
        selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("กรุณากรอกข้อมูลให้ครบทุกช่อง ⚠️")),
      );
      return;
    }

    try {
      await db.collection("Products").add({
        "senderId": widget.userId,
        "senderName": senderInfo!['fullname'],
        "senderPhone": senderInfo!['phone'],
        "senderLocation": senderInfo!['location'],
        "productName": productNameCtl.text,
        "receiverId": selectedUser!['id'],
        "receiverName": selectedUser!['fullname'],
        "receiverPhone": selectedUser!['phone'],
        "receiverLocation": selectedLocation,
        "productImage": productImageBase64,
        "status": "รอไรเดอร์มารับสินค้า",
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เพิ่มสินค้าเรียบร้อย ✅")));

      productNameCtl.clear();
      searchPhoneCtl.clear();
      setState(() {
        selectedUser = null;
        selectedLocation = null;
        productImageBase64 = '';
        filteredUsers = [];
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
    searchPhoneCtl.dispose();
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

            const Text("ค้นหาผู้รับสินค้า", style: TextStyle(fontSize: 16)),
            TextField(
              controller: searchPhoneCtl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "กรอกหมายเลขโทรศัพท์",
                filled: true,
              ),
              onChanged: filterUsers,
            ),

            if (searchPhoneCtl.text.isNotEmpty && filteredUsers.isNotEmpty)
              Container(
                height: 150,
                margin: const EdgeInsets.only(top: 5),
                child: ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return ListTile(
                      leading: const Icon(Icons.person, color: Colors.orange),
                      title: Text(user['fullname'] ?? '-'),
                      subtitle: Text(user['phone'] ?? '-'),
                      onTap: () {
                        setState(() {
                          selectedUser = user;
                          searchPhoneCtl.clear();
                          filteredUsers = [];
                          selectedLocation = null;
                        });
                      },
                    );
                  },
                ),
              ),

            if (selectedUser != null)
              Card(
                color: Colors.orange.shade50,
                margin: const EdgeInsets.only(top: 10, bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFF8C42), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "ข้อมูลผู้รับสินค้า",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const Divider(),
                      Text("👤 ชื่อ: ${selectedUser!['fullname'] ?? '-'}"),
                      Text("📞 เบอร์โทร: ${selectedUser!['phone'] ?? '-'}"),
                      if (selectedUser!['email'] != null)
                        Text("📧 อีเมล: ${selectedUser!['email']}"),
                      if (selectedUser!['address'] != null)
                        Text("🏠 ที่อยู่: ${selectedUser!['address']}"),
                      if (selectedUser!['location'] != null)
                        Text(
                          "📍 ตำแหน่งหลัก: (${selectedUser!['location']['lat']}, ${selectedUser!['location']['lng']})",
                        ),
                      if (selectedUser!['location2'] != null)
                        Text(
                          "📍 ตำแหน่งสำรอง: (${selectedUser!['location2']['lat']}, ${selectedUser!['location2']['lng']})",
                        ),
                    ],
                  ),
                ),
              ),

            if (selectedUser != null &&
                (selectedUser!['location'] != null ||
                    selectedUser!['location2'] != null))
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "เลือกตำแหน่งผู้รับสินค้า",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),

                  DropdownButtonFormField<String>(
                    value: selectedLocation == null
                        ? null
                        : (mapEquals(selectedLocation!, {
                                'lat': selectedUser!['location']?['lat'],
                                'lng': selectedUser!['location']?['lng'],
                              })
                              ? 'main'
                              : 'alt'),
                    items: [
                      if (selectedUser!['location'] != null)
                        DropdownMenuItem(
                          value: 'main',
                          child: Text(
                            "ตำแหน่งหลัก (${selectedUser!['location']['lat']}, ${selectedUser!['location']['lng']})",
                          ),
                        ),
                      if (selectedUser!['location2'] != null)
                        DropdownMenuItem(
                          value: 'alt',
                          child: Text(
                            "ตำแหน่งสำรอง (${selectedUser!['location2']['lat']}, ${selectedUser!['location2']['lng']})",
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        if (value == 'main') {
                          selectedLocation = {
                            'lat': selectedUser!['location']['lat'],
                            'lng': selectedUser!['location']['lng'],
                          };
                        } else if (value == 'alt') {
                          selectedLocation = {
                            'lat': selectedUser!['location2']['lat'],
                            'lng': selectedUser!['location2']['lng'],
                          };
                        } else {
                          selectedLocation = null;
                        }
                      });
                    },
                    decoration: const InputDecoration(
                      filled: true,
                      hintText: "เลือกตำแหน่งผู้รับ",
                    ),
                  ),

                  const SizedBox(height: 10),

                  if (selectedLocation != null)
                    Container(
                      height: 250,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(
                              selectedLocation!['lat']!,
                              selectedLocation!['lng']!,
                            ),
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=eeb2695f683043e1a2cb2968a6a51064',
                              userAgentPackageName: 'com.example.delivery_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    selectedLocation!['lat']!,
                                    selectedLocation!['lng']!,
                                  ),
                                  width: 50,
                                  height: 50,
                                  child: const Icon(
                                    Icons.location_pin,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                  border: Border.all(color: const Color(0xFFFF8C42), width: 3),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image, color: Color(0xFFFF8C42)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        productImageBase64.isEmpty
                            ? "เลือกรูปสินค้า (ถ่ายภาพหรือเลือกจากอัลบั้ม)"
                            : "อัปโหลดรูปสินค้าแล้ว ✅",
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (productImageBase64.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Image.memory(
                  base64Decode(productImageBase64),
                  height: 150,
                  fit: BoxFit.cover,
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

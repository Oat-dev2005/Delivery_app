import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:delivery_app/pages/rider/homepage_rider.dart';

class RiderCurrentJobPage extends StatefulWidget {
  final String productId;
  final String riderId;

  const RiderCurrentJobPage({
    super.key,
    required this.productId,
    required this.riderId,
  });

  @override
  State<RiderCurrentJobPage> createState() => _RiderCurrentJobPageState();
}

class _RiderCurrentJobPageState extends State<RiderCurrentJobPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<Map<String, String>> getSenderInfo(String senderId) async {
    try {
      if (senderId.isEmpty) return {'name': '-', 'phone': '-'};
      final doc = await db.collection('Users').doc(senderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {'name': data['fullname'] ?? '-', 'phone': data['phone'] ?? '-'};
      }
    } catch (e) {}
    return {'name': '-', 'phone': '-'};
  }

  /// ✅ ฟังก์ชัน "ส่งของสำเร็จ"
  Future<void> completeDelivery() async {
    if (!mounted) return;

    try {
      // 1️⃣ อัปเดตสถานะสินค้า
      await db.collection("Products").doc(widget.productId).update({
        "status": "จัดส่งสำเร็จ ✅",
      });

      // 2️⃣ ดึงข้อมูลไรเดอร์
      final riderDoc = await db.collection("Users").doc(widget.riderId).get();
      final phone = riderDoc['phone'] ?? '';
      final role = riderDoc['role'] ?? '';
      final userId = widget.riderId;

      // 3️⃣ เคลียร์งานปัจจุบันของไรเดอร์
      await db.collection("Users").doc(widget.riderId).update({
        "currentJobId": "",
      });

      // 4️⃣ แสดง SnackBar แจ้งเตือน
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ ส่งของสำเร็จแล้ว!")));

      // 5️⃣ รอ 2 วินาทีแล้วกลับไปหน้า HomepageRider
      await Future.delayed(const Duration(seconds: 2));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              HomepageRider(phone: phone, role: role, userId: userId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
    }
  }

  /// 📸 ฟังก์ชันถ่ายรูปและอัปเดตสถานะ
  Future<void> takePhotoAndUpdateStatus({
    required String fieldName,
    required String newStatus,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo == null) return;

      final bytes = await File(photo.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      await db.collection("Products").doc(widget.productId).update({
        fieldName: base64Image,
        "status": newStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📸 ถ่ายรูปและอัปเดตสถานะเรียบร้อย!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: db.collection("Products").doc(widget.productId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData ||
            snapshot.data == null ||
            !snapshot.data!.exists) {
          db.collection("Users").doc(widget.riderId).update({
            "currentJobId": "",
          });

          return const Scaffold(
            body: Center(child: Text("ไม่พบข้อมูลงานนี้ (อาจถูกลบไปแล้ว)")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        if (data == null) {
          return const Scaffold(body: Center(child: Text("ไม่พบข้อมูลงานนี้")));
        }

        Map<String, double>? receiverLocation;
        if (data['receiverLocation'] != null) {
          receiverLocation = {
            'lat': data['receiverLocation']['lat'],
            'lng': data['receiverLocation']['lng'],
          };
        }

        final hasPickupPhoto =
            data['pickupImage'] != null &&
            data['pickupImage'].toString().isNotEmpty;
        final hasDeliveredPhoto =
            data['deliveredImage'] != null &&
            data['deliveredImage'].toString().isNotEmpty;

        return FutureBuilder<Map<String, String>>(
          future: getSenderInfo(data['senderId'] ?? ''),
          builder: (context, senderSnapshot) {
            final senderName = senderSnapshot.data?['name'] ?? '-';
            final senderPhone = senderSnapshot.data?['phone'] ?? '-';

            return Scaffold(
              appBar: AppBar(
                backgroundColor: const Color(0xFFFFA64C),
                title: const Text("งานปัจจุบันของฉัน"),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'logout') {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                          (route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("ออกจากระบบสำเร็จ ✅")),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Text('ออกจากระบบ'),
                      ),
                    ],
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // รูปสินค้า
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          data['productImage'] != null &&
                              data['productImage'].toString().isNotEmpty
                          ? Image.memory(
                              base64Decode(data['productImage']),
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              'assets/no_image.png',
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(height: 20),

                    // ข้อมูลสินค้า
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Color(0xFFFF8C42),
                          width: 1.5,
                        ),
                      ),
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ข้อมูลสินค้า',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade800,
                              ),
                            ),
                            const Divider(color: Colors.orange),
                            Text(
                              '📦 ชื่อสินค้า: ${data['productName'] ?? '-'}',
                            ),
                            const SizedBox(height: 5),
                            Text('🚚 ผู้ส่ง: $senderName'),
                            const SizedBox(height: 5),
                            Text('📞 เบอร์ผู้ส่ง: $senderPhone'),
                            const SizedBox(height: 5),
                            Text('👤 ผู้รับ: ${data['receiverName'] ?? '-'}'),
                            const SizedBox(height: 5),
                            Text(
                              '📞 เบอร์ผู้รับ: ${data['receiverPhone'] ?? '-'}',
                            ),
                            const SizedBox(height: 5),
                            Text('📍 สถานะ: ${data['status'] ?? '-'}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // แผนที่ผู้รับ
                    if (receiverLocation != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "ตำแหน่งผู้รับสินค้า",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.orange,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    receiverLocation['lat']!,
                                    receiverLocation['lng']!,
                                  ),
                                  initialZoom: 15,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.thunderforest.com/atlas/{z}/{x}/{y}.png?apikey=eeb2695f683043e1a2cb2968a6a51064',
                                    userAgentPackageName:
                                        'com.example.delivery_app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          receiverLocation['lat']!,
                                          receiverLocation['lng']!,
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

                    const SizedBox(height: 30),

                    // ถ่ายรูปตอนรับสินค้า
                    ElevatedButton.icon(
                      onPressed: () => takePhotoAndUpdateStatus(
                        fieldName: "pickupImage",
                        newStatus: "ไรเดอร์รับสินค้าแล้ว กำลังเดินทางไปส่ง 🚚",
                      ),
                      icon: const Icon(Icons.camera_alt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      label: const Text(
                        "📸 ถ่ายรูปตอนรับสินค้า",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    if (hasPickupPhoto)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.memory(
                          base64Decode(data['pickupImage']),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                    const SizedBox(height: 20),

                    // ถ่ายรูปตอนส่งสินค้า
                    ElevatedButton.icon(
                      onPressed: hasPickupPhoto
                          ? () => takePhotoAndUpdateStatus(
                              fieldName: "deliveredImage",
                              newStatus: "ไรเดอร์ส่งสินค้าแล้ว 📦",
                            )
                          : null,
                      icon: const Icon(Icons.local_shipping),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasPickupPhoto
                            ? Colors.orange
                            : Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      label: const Text(
                        "📸 ถ่ายรูปตอนส่งสินค้า",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                    if (hasDeliveredPhoto)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Image.memory(
                          base64Decode(data['deliveredImage']),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 30),

                    // ปุ่มส่งของสำเร็จ
                    if (hasDeliveredPhoto)
                      ElevatedButton.icon(
                        onPressed: completeDelivery,
                        icon: const Icon(Icons.check_circle_outline),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: const Text(
                          "✅ ส่งของสำเร็จ",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:delivery_app/pages/rider/Riderlocation_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Detail_customer extends StatelessWidget {
  final Map<String, dynamic> productData;
  final String senderName;
  final String senderPhone;

  const Detail_customer({
    super.key,
    required this.productData,
    required this.senderName,
    required this.senderPhone,
  });

  @override
  Widget build(BuildContext context) {
    // ตรวจสอบตำแหน่งผู้รับ (ถ้ามี)
    Map<String, double>? receiverLocation;
    if (productData['receiverLocation'] != null) {
      receiverLocation = {
        'lat': productData['receiverLocation']['lat'],
        'lng': productData['receiverLocation']['lng'],
      };
    }

    // ตรวจสอบเบอร์ผู้ส่ง fallback
    String senderPhone =
        productData['senderPhone'] != null &&
            productData['senderPhone'].toString().isNotEmpty
        ? productData['senderPhone']
        : '-';

    // ✅ ดึงรูปที่ไรเดอร์อัพโหลด
    final String? pickupImage = productData['pickupImage'];
    final String? deliveredImage = productData['deliveredImage'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดสินค้า (customer)"),
        backgroundColor: const Color(0xFFFF8C42),
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
                  productData['productImage'] != null &&
                      productData['productImage'].toString().isNotEmpty
                  ? Image.memory(
                      base64Decode(productData['productImage']),
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
                side: const BorderSide(color: Color(0xFFFF8C42), width: 1.5),
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
                    Text('📦 ชื่อสินค้า: ${productData['productName'] ?? '-'}'),
                    const SizedBox(height: 5),
                    Text('🚚 ผู้ส่ง: $senderName'),
                    const SizedBox(height: 5),
                    Text('📞 เบอร์ผู้ส่ง: $senderPhone'),
                    const SizedBox(height: 5),
                    Text('👤 ผู้รับ: ${productData['receiverName'] ?? '-'}'),
                    const SizedBox(height: 5),
                    Text(
                      '📞 เบอร์ผู้รับ: ${productData['receiverPhone'] ?? '-'}',
                    ),
                    const SizedBox(height: 5),
                    Text('📍 สถานะ: ${productData['status'] ?? '-'}'),
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
                      border: Border.all(color: Colors.orange, width: 2),
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
                            userAgentPackageName: 'com.example.delivery_app',
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

            const SizedBox(height: 20),

            // ✅ รูปที่ไรเดอร์ถ่ายตอนรับสินค้า
            if (pickupImage != null && pickupImage.isNotEmpty) ...[
              const Text(
                "📸 รูปตอนรับสินค้า:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(pickupImage),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ✅ รูปที่ไรเดอร์ถ่ายตอนส่งสินค้า
            if (deliveredImage != null && deliveredImage.isNotEmpty) ...[
              const Text(
                "📦 รูปตอนส่งสินค้า:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(deliveredImage),
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            if (productData['status'] ==
                    'ไรเดอร์รับงานแล้ว (กำลังเดินทางมารับสินค้า)' ||
                productData['status'] ==
                    'ไรเดอร์รับสินค้าแล้ว กำลังเดินทางไปส่ง 🚚') ...[
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RiderlocationPage(
                          riderId: productData['riderId'], // ต้องมีใน Firestore
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "ดูตำแหน่งไรเดอร์",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

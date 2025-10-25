import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delivery_app/pages/customer/Detail_customer.dart';
import 'package:delivery_app/pages/customer/add_product.dart';
import 'package:delivery_app/pages/customer/homepage_receiver.dart';
import 'package:delivery_app/pages/login.dart';
import 'package:flutter/material.dart';

class HomepageCustomer extends StatefulWidget {
  final String phone;
  final String role;
  final String userId;

  const HomepageCustomer({
    super.key,
    required this.phone,
    required this.role,
    required this.userId,
  });

  @override
  State<HomepageCustomer> createState() => _HomepageCustomerState();
}

class _HomepageCustomerState extends State<HomepageCustomer> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  String searchText = "";

  Future<Map<String, String>> getRiderInfo(String? riderId) async {
    try {
      if (riderId == null || riderId.isEmpty)
        return {'name': '-', 'phone': '-'};
      final doc = await db.collection('Users').doc(riderId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {'name': data['fullname'] ?? '-', 'phone': data['phone'] ?? '-'};
      }
    } catch (e) {}
    return {'name': '-', 'phone': '-'};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C42),
        automaticallyImplyLeading: false,
        title: const Text(
          'รายการสินค้าของฉัน',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ออกจากระบบสำเร็จ ✅")),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'logout', child: Text('ออกจากระบบ')),
            ],
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
                border: Border.all(color: const Color(0xFFFF8C42)),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Color(0xFFFF8C42)),
                  hintText: 'ค้นหาชื่อสินค้า',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 10),

            // 🧃 แสดงรายการสินค้า
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: db
                    .collection("Products")
                    .where("senderId", isEqualTo: widget.userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final products = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['productName'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(searchText);
                  }).toList();

                  if (products.isEmpty) {
                    return const Center(child: Text("ยังไม่มีรายการสินค้า 🚚"));
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final data =
                          products[index].data() as Map<String, dynamic>;
                      // final productId = products[index].id;

                      return FutureBuilder<Map<String, String>>(
                        future: getRiderInfo(data['riderId'] ?? ''),
                        builder: (context, riderSnapshot) {
                          final riderName = riderSnapshot.data?['name'] ?? '-';
                          final riderPhone =
                              riderSnapshot.data?['phone'] ?? '-';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Detail_customer(
                                    productData: data,
                                    senderName: data['senderName'] ?? '-',
                                    senderPhone: data['senderPhone'] ?? '-',
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFE5CC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 🖼 รูปภาพสินค้า
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        data['productImage'] != null &&
                                            data['productImage']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.memory(
                                            base64Decode(data['productImage']),
                                            width: 90,
                                            height: 90,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            'assets/no_image.png',
                                            width: 90,
                                            height: 90,
                                          ),
                                  ),
                                  const SizedBox(width: 10),

                                  // 📋 รายละเอียดสินค้า
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['productName'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text("ผู้ส่ง: ${widget.phone}"),
                                        Text(
                                          "ผู้รับ: ${data['receiverName'] ?? '-'}",
                                        ),
                                        Text(
                                          "เบอร์ผู้รับ: ${data['receiverPhone'] ?? '-'}",
                                        ),
                                        Text("ไรเดอร์: $riderName"),
                                        Text("เบอร์ไรเดอร์: $riderPhone"),
                                        const SizedBox(height: 4),
                                        Text(
                                          "[สถานะ]: ${data['status'] ?? 'ไม่มีสถานะ'}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
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
                },
              ),
            ),

            // 🧡 ปุ่ม create orders
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddProductPage(userId: widget.userId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C42),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "เพิ่มสินค้าใหม่",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),

      // ⚙️ bottom navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFF8C42),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomepageReceiver(
                  phone: widget.phone,
                  role: widget.role,
                  userId: widget.userId,
                ),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "ส่งสินค้า"),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: "รับสินค้า",
          ),
        ],
      ),
    );
  }
}

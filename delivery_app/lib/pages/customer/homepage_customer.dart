import 'package:delivery_app/pages/login.dart';
import 'package:flutter/material.dart';

class HomepageCustomer extends StatefulWidget {
  // const HomepageCustomer({super.key});
  final String phone;
  final String role;

  const HomepageCustomer({super.key, required this.phone, required this.role});

  @override
  State<HomepageCustomer> createState() => _HomepageCustomerState();
}

class _HomepageCustomerState extends State<HomepageCustomer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ข่อยเป็นลูกค้า'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false, // เคลียร์ทุกหน้าออกจาก stack
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'เบอร์โทร : ${widget.phone}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Role : ${widget.role}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

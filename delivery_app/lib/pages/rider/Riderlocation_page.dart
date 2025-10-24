import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RiderlocationPage extends StatefulWidget {
  final String riderId;
  const RiderlocationPage({super.key, required this.riderId});

  @override
  State<RiderlocationPage> createState() => _RiderlocationPageState();
}

class _RiderlocationPageState extends State<RiderlocationPage> {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("rider map"),
        backgroundColor: const Color(0xFFFF8C42),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: db.collection('riderLocation').doc(widget.riderId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(
              child: Text("ยังไม่มีข้อมูลตำแหน่งของไรเดอร์ 🚴"),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final lat = data['lat'];
          final lng = data['lng'];

          if (lat == null || lng == null) {
            return const Center(child: Text("ไม่พบค่าพิกัดของไรเดอร์ ❌"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
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
                              point: LatLng(lat, lng),
                              width: 60,
                              height: 60,
                              child: const Icon(
                                Icons.pedal_bike,
                                color: Colors.blue,
                                size: 45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "กลับ",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

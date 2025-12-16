import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sri Lanka Map',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SriLankaMapPage(),
    );
  }
}

class SriLankaMapPage extends StatefulWidget {
  const SriLankaMapPage({super.key});

  @override
  State<SriLankaMapPage> createState() => _SriLankaMapPageState();
}

class _SriLankaMapPageState extends State<SriLankaMapPage> {
  final MapController _mapController = MapController();

  // Sri Lanka's approximate center coordinates
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  // Major cities in Sri Lanka
  final List<Marker> _markers = [
    Marker(
      point: const LatLng(6.9271, 79.8612), // Colombo
      width: 80,
      height: 80,
      child: Column(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 40),
          Text('Colombo', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
    Marker(
      point: const LatLng(7.2906, 80.6337), // Kandy
      width: 80,
      height: 80,
      child: Column(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 40),
          Text('Kandy', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
    Marker(
      point: const LatLng(9.6615, 80.0255), // Jaffna
      width: 80,
      height: 80,
      child: Column(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 40),
          Text('Jaffna', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
    Marker(
      point: const LatLng(6.0535, 80.2210), // Galle
      width: 80,
      height: 80,
      child: Column(
        children: [
          Icon(Icons.location_on, color: Colors.red, size: 40),
          Text('Galle', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Map'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_sriLankaCenter, 7.5);
            },
            tooltip: 'Reset to Sri Lanka',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _sriLankaCenter,
          initialZoom: 7.5,
          minZoom: 6.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.srilanka.sri_lanka_app',
            maxZoom: 19,
          ),
          MarkerLayer(
            markers: _markers,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom + 1);
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () {
              final currentZoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, currentZoom - 1);
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

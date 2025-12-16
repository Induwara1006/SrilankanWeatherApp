import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/region.dart';
import 'services/weather_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization error: $e');
  }
  
  // Anonymous sign-in
  try {
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    print('Anonymous auth error: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sri Lanka Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SriLankaWeatherPage(),
    );
  }
}

class SriLankaWeatherPage extends StatefulWidget {
  const SriLankaWeatherPage({super.key});

  @override
  State<SriLankaWeatherPage> createState() => _SriLankaWeatherPageState();
}

class _SriLankaWeatherPageState extends State<SriLankaWeatherPage> {
  final MapController _mapController = MapController();
  final WeatherRepository _repository = WeatherRepository();
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);

  IconData _getWeatherIcon(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.sunny:
        return Icons.wb_sunny;
      case WeatherStatus.rainy:
        return Icons.water_drop;
      case WeatherStatus.cloudy:
        return Icons.cloud;
    }
  }

  Color _getWeatherColor(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.sunny:
        return Colors.orange;
      case WeatherStatus.rainy:
        return Colors.blue;
      case WeatherStatus.cloudy:
        return Colors.grey;
    }
  }

  void _showUpdateDialog(Region region) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Update weather for ${region.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.wb_sunny, color: Colors.orange, size: 32),
              title: const Text('Sunny'),
              onTap: () {
                _repository.updateRegion(region.id, WeatherStatus.sunny);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${region.name} to Sunny')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.water_drop, color: Colors.blue, size: 32),
              title: const Text('Rainy'),
              onTap: () {
                _repository.updateRegion(region.id, WeatherStatus.rainy);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${region.name} to Rainy')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud, color: Colors.grey, size: 32),
              title: const Text('Cloudy'),
              onTap: () {
                _repository.updateRegion(region.id, WeatherStatus.cloudy);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated ${region.name} to Cloudy')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildMarkers(List<Region> regions) {
    return regions.map((region) {
      return Marker(
        point: region.position,
        width: 100,
        height: 100,
        child: GestureDetector(
          onTap: () => _showUpdateDialog(region),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getWeatherColor(region.status).withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(region.status),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  region.name,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Weather'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const Text(
                    'Tap on any district marker to update its weather status.\n\n'
                    '🌞 Sunny - Clear weather\n'
                    '💧 Rainy - Rainy conditions\n'
                    '☁️ Cloudy - Cloudy skies\n\n'
                    'Your updates are visible to all users in realtime!',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              _mapController.move(_sriLankaCenter, 7.5);
            },
            tooltip: 'Reset View',
          ),
        ],
      ),
      body: StreamBuilder<List<Region>>(
        stream: _repository.watchRegions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Make sure Firebase is configured.\nRun: flutterfire configure',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final regions = snapshot.data ?? [];

          if (regions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No regions found. Initialize data?'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _repository.seedRegionsIfEmpty();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Regions initialized!'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Seed Regions'),
                  ),
                ],
              ),
            );
          }

          return FlutterMap(
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
                markers: _buildMarkers(regions),
              ),
            ],
          );
        },
      ),
    );
  }
}

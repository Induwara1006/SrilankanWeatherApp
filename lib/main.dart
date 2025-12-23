import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'models/region.dart';
import 'services/weather_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sri Lanka Weather',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: AppInitializer(onToggleTheme: _toggleTheme),
    );
  }
}

class AppInitializer extends StatefulWidget {
  final VoidCallback onToggleTheme;
  
  const AppInitializer({super.key, required this.onToggleTheme});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await FirebaseAuth.instance.signInAnonymously();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SriLankaWeatherPage(onToggleTheme: widget.onToggleTheme)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Initialize',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _errorMessage = null);
                    _initializeApp();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud, size: 80, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Sri Lanka Weather',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class SriLankaWeatherPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  
  const SriLankaWeatherPage({super.key, required this.onToggleTheme});

  @override
  State<SriLankaWeatherPage> createState() => _SriLankaWeatherPageState();
}

class _SriLankaWeatherPageState extends State<SriLankaWeatherPage> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  final WeatherRepository _repository = WeatherRepository();
  static const LatLng _sriLankaCenter = LatLng(7.8731, 80.7718);
  bool _isUpdating = false;
  bool _showLegend = true;
  bool _isInteracting = false;
  
  // Cache for markers
  List<Marker>? _cachedMarkers;
  List<Marker>? _cachedSimpleMarkers;
  List<Region>? _cachedRegions;
  
  // Debounce timer
  Timer? _interactionDebounce;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void dispose() {
    _interactionDebounce?.cancel();
    super.dispose();
  }

  // Static cache for weather attributes to prevent repeated allocations
  static const Map<WeatherStatus, IconData> _weatherIcons = {
    WeatherStatus.sunny: Icons.wb_sunny,
    WeatherStatus.rainy: Icons.water_drop,
    WeatherStatus.cloudy: Icons.cloud,
    WeatherStatus.stormy: Icons.thunderstorm,
    WeatherStatus.flood: Icons.flood,
  };
  
  static const Map<WeatherStatus, Color> _weatherColors = {
    WeatherStatus.sunny: Colors.orange,
    WeatherStatus.rainy: Colors.blue,
    WeatherStatus.cloudy: Colors.grey,
    WeatherStatus.stormy: Colors.purple,
    WeatherStatus.flood: Colors.red,
  };
  
  static const Map<WeatherStatus, String> _weatherLabels = {
    WeatherStatus.sunny: 'Sunny',
    WeatherStatus.rainy: 'Rainy',
    WeatherStatus.cloudy: 'Cloudy',
    WeatherStatus.stormy: 'Stormy',
    WeatherStatus.flood: 'Flood',
  };

  IconData _getWeatherIcon(WeatherStatus status) => _weatherIcons[status]!;
  Color _getWeatherColor(WeatherStatus status) => _weatherColors[status]!;
  String _getWeatherLabel(WeatherStatus status) => _weatherLabels[status]!;
  
  void _setInteracting(bool value) {
    _interactionDebounce?.cancel();
    
    if (value) {
      if (!_isInteracting) {
        setState(() => _isInteracting = true);
      }
    } else {
      _interactionDebounce = Timer(const Duration(milliseconds: 200), () {
        if (mounted && _isInteracting) {
          setState(() => _isInteracting = false);
        }
      });
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  void _showUpdateDialog(Region region) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              region.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${_formatTimeAgo(region.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Weather Condition',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildWeatherChip(region, WeatherStatus.sunny, 'Sunny', Icons.wb_sunny, Colors.orange),
                _buildWeatherChip(region, WeatherStatus.rainy, 'Rainy', Icons.water_drop, Colors.blue),
                _buildWeatherChip(region, WeatherStatus.cloudy, 'Cloudy', Icons.cloud, Colors.grey),
                _buildWeatherChip(region, WeatherStatus.stormy, 'Stormy', Icons.thunderstorm, Colors.purple),
                _buildWeatherChip(region, WeatherStatus.flood, 'Flood', Icons.flood, Colors.red),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherChip(Region region, WeatherStatus status, String label, IconData icon, Color color) {
    final isSelected = region.status == status;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? Colors.white : color),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (_) async {
        Navigator.pop(context);
        setState(() => _isUpdating = true);
        try {
          await _repository.updateRegion(region.id, status);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✓ Updated ${region.name} to $label'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isUpdating = false);
          }
        }
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  List<Marker> _buildMarkers(List<Region> regions) {
    return regions.map((region) {
      return Marker(
        point: region.position,
        width: 110,
        height: 110,
        child: GestureDetector(
          onTap: () => _showUpdateDialog(region),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getWeatherColor(region.status),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getWeatherColor(region.status).withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  _getWeatherIcon(region.status),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxWidth: 90),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  region.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Weather'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Theme.of(context).brightness == Brightness.dark 
              ? Icons.light_mode 
              : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
            tooltip: Theme.of(context).brightness == Brightness.dark 
              ? 'Light Mode' 
              : 'Dark Mode',
          ),
          IconButton(
            icon: Icon(_showLegend ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() => _showLegend = !_showLegend);
            },
            tooltip: _showLegend ? 'Hide Legend' : 'Show Legend',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Use'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tap on any district marker to update its weather status.\n',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text('🌞 Sunny - Clear weather'),
                        Text('💧 Rainy - Rainy conditions'),
                        Text('☁️ Cloudy - Cloudy skies'),
                        Text('⛈️ Stormy - Thunderstorms'),
                        Text('🌊 Flood - Flooding conditions'),
                        SizedBox(height: 16),
                        Text(
                          'Your updates are visible to all users in realtime!',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
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
        stream: _repository.watchRegions().distinct((prev, next) {
          // Only rebuild if actual data changes
          if (prev.length != next.length) return false;
          for (int i = 0; i < prev.length; i++) {
            if (prev[i].id != next[i].id || 
                prev[i].status != next[i].status ||
                prev[i].updatedAt != next[i].updatedAt) {
              return false;
            }
          }
          return true;
        }),
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

          return RefreshIndicator(
            onRefresh: () async {
              // The stream will automatically update
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _sriLankaCenter,
                    initialZoom: 7.5,
                    minZoom: 6.0,
                    maxZoom: 18.0,
                    keepAlive: true,
                    onMapEvent: (event) {
                      if (event is MapEventMoveStart || event is MapEventFlingAnimationStart) {
                        _setInteracting(true);
                      } else if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                        _setInteracting(false);
                      }
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                      pinchZoomThreshold: 0.5,
                      scrollWheelVelocity: 0.005,
                      pinchMoveThreshold: 40.0,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.srilanka.sri_lanka_app',
                      maxZoom: 19,
                      maxNativeZoom: 19,
                      panBuffer: 1,
                      keepBuffer: 2,
                      retinaMode: false,
                      tileDisplay: _isInteracting 
                        ? const TileDisplay.instantaneous()
                        : const TileDisplay.fadeIn(
                            duration: Duration(milliseconds: 80),
                          ),
                    ),
                    MarkerLayer(
                      markers: _buildMarkers(regions, simple: _isInteracting),
                      rotate: false,
                    ),
                  ],
                ),
                if (_showLegend)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: RepaintBoundary(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Legend',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem(Icons.wb_sunny, 'Sunny', Colors.orange),
                          _buildLegendItem(Icons.water_drop, 'Rainy', Colors.blue),
                          _buildLegendItem(Icons.cloud, 'Cloudy', Colors.grey),
                          _buildLegendItem(Icons.thunderstorm, 'Stormy', Colors.purple),
                          _buildLegendItem(Icons.flood, 'Flood', Colors.red),
                        ],
                      ),
                    ),
                  ),
                if (_isUpdating)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

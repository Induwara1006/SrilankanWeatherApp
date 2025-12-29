import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/weather_controller.dart';
import '../models/region.dart';
import '../models/user_marker.dart';
import '../services/user_marker_repository.dart';
import 'widgets/legend_widget.dart';
import 'widgets/region_marker_widget.dart';
import 'widgets/weather_update_dialog.dart';
import 'widgets/add_marker_dialog.dart';
import 'widgets/user_marker_widget.dart';
import 'widgets/marker_detail_dialog.dart';

class WeatherMapView extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const WeatherMapView({super.key, required this.onToggleTheme});

  @override
  State<WeatherMapView> createState() => _WeatherMapViewState();
}

class _WeatherMapViewState extends State<WeatherMapView>
    with AutomaticKeepAliveClientMixin {
  late final WeatherController _controller;
  final UserMarkerRepository _markerRepository = UserMarkerRepository();
  bool _isAddingMarker = false;

  @override
  void initState() {
    super.initState();
    _controller = WeatherController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _showUpdateDialog(Region region) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => WeatherUpdateDialog(
        region: region,
        controller: _controller,
      ),
    );
  }

  void _showInfoDialog() {
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
                'Weather Updates:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
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
                'Add Your Own Markers:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Enable marker mode and tap anywhere on the map to add notes, photos, warnings, events, or places. All users can see your markers!\n',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Updates are visible to all users in realtime!',
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
  }

  void _handleMapTap(LatLng position) {
    if (_isAddingMarker) {
      showDialog(
        context: context,
        builder: (context) => AddMarkerDialog(
          position: position,
          onAdd: (marker) async {
            try {
              await _markerRepository.addMarker(marker);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marker added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to add marker: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      );
    } else {
      _controller.handleTapForDoubleClick(position);
    }
  }

  void _showMarkerDetails(UserMarker marker) {
    showDialog(
      context: context,
      builder: (context) => MarkerDetailDialog(
        marker: marker,
        onDelete: () async {
          try {
            await _markerRepository.deleteMarker(marker.id);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Marker deleted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to delete marker: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onUpdateWeather: (status, updatedBy) async {
          try {
            await _markerRepository.updateWeatherStatus(
              marker.id,
              statusToString(status),
              updatedBy,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Weather status updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update weather: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _toggleAddMarkerMode() {
    setState(() {
      _isAddingMarker = !_isAddingMarker;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAddingMarker
              ? 'Tap anywhere on the map to add a marker'
              : 'Marker mode disabled',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isAddingMarker ? Colors.green : Colors.grey,
      ),
    );
  }

  List<Marker> _buildMarkers(List<Region> regions) {
    return regions.map((region) {
      return Marker(
        key: ValueKey(region.id),
        point: region.position,
        width: 110,
        height: 110,
        child: RepaintBoundary(
          child: RegionMarkerWidget(
            region: region,
            controller: _controller,
            onTap: () => _showUpdateDialog(region),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.location_on, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Serendip',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.grey.shade900, Colors.grey.shade800]
                  : [Colors.blue.shade50, Colors.teal.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: _isAddingMarker
                  ? Colors.green.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: _isAddingMarker
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                _isAddingMarker ? Icons.add_location : Icons.add_location_alt_outlined,
                color: _isAddingMarker ? Colors.green : null,
              ),
              onPressed: _toggleAddMarkerMode,
              tooltip: _isAddingMarker ? 'Disable Marker Mode' : 'Add Marker',
            ),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return IconButton(
                icon: Icon(_controller.showLegend
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: _controller.toggleLegend,
                tooltip: _controller.showLegend ? 'Hide Legend' : 'Show Legend',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _controller.resetMapView,
            tooltip: 'Reset View',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<Region>>(
        stream: _controller.watchRegions(),
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
                    onPressed: () => _controller.seedRegions(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Seed Regions'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Stack(
              children: [
                RepaintBoundary(
                  child: FlutterMap(
                    mapController: _controller.mapController,
                    options: MapOptions(
                      initialCenter: WeatherController.sriLankaCenter,
                      initialZoom: 7.5,
                      minZoom: 6.0,
                      maxZoom: 18.0,
                      keepAlive: true,
                      onTap: (tapPosition, point) {
                        _handleMapTap(point);
                      },
                      onMapEvent: (event) {
                        if (event is MapEventMoveStart ||
                            event is MapEventFlingAnimationStart) {
                          _controller.setInteracting(true);
                        } else if (event is MapEventMoveEnd ||
                            event is MapEventFlingAnimationEnd) {
                          _controller.setInteracting(false);
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
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: isDark ? const ['a', 'b', 'c', 'd'] : const [],
                        userAgentPackageName: 'com.srilanka.sri_lanka_app',
                        maxZoom: 19,
                        maxNativeZoom: 19,
                        panBuffer: 0,
                        keepBuffer: 3,
                        retinaMode: false,
                        tileDisplay: _controller.isInteracting
                            ? const TileDisplay.instantaneous()
                            : const TileDisplay.fadeIn(
                                duration: Duration(milliseconds: 100),
                              ),
                        tileBuilder: (context, widget, tile) {
                          return RepaintBoundary(child: widget);
                        },
                      ),
                      MarkerLayer(
                        markers: _buildMarkers(regions),
                        rotate: false,
                      ),
                      StreamBuilder<List<UserMarker>>(
                        stream: _markerRepository.watchUserMarkers(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          final userMarkers = snapshot.data!;
                          return MarkerLayer(
                            markers: userMarkers.map((marker) {
                              return Marker(
                                key: ValueKey(marker.id),
                                point: marker.position,
                                width: 110,
                                height: 110,
                                child: UserMarkerWidget(
                                  marker: marker,
                                  onTap: () => _showMarkerDetails(marker),
                                ),
                              );
                            }).toList(),
                            rotate: false,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (!_controller.showLegend) return const SizedBox.shrink();
                    return const Positioned(
                      top: 16,
                      right: 16,
                      child: RepaintBoundary(child: LegendWidget()),
                    );
                  },
                ),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    if (!_controller.isUpdating) return const SizedBox.shrink();
                    return Container(
                      color: Colors.black26,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

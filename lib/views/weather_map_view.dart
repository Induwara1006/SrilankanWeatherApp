import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../controllers/weather_controller.dart';
import '../models/region.dart';
import 'widgets/legend_widget.dart';
import 'widgets/region_marker_widget.dart';
import 'widgets/weather_update_dialog.dart';

class WeatherMapView extends StatefulWidget {
  final VoidCallback onToggleTheme;

  const WeatherMapView({super.key, required this.onToggleTheme});

  @override
  State<WeatherMapView> createState() => _WeatherMapViewState();
}

class _WeatherMapViewState extends State<WeatherMapView>
    with AutomaticKeepAliveClientMixin {
  late final WeatherController _controller;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sri Lanka Weather'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Light Mode'
                : 'Dark Mode',
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
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _controller.resetMapView,
            tooltip: 'Reset View',
          ),
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
                        // Double-tap to zoom in
                        _controller.handleTapForDoubleClick(point);
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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

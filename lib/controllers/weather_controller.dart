import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/region.dart';
import '../services/weather_repository.dart';

class WeatherController extends ChangeNotifier {
  final WeatherRepository _repository = WeatherRepository();
  final MapController mapController = MapController();
  
  static const LatLng sriLankaCenter = LatLng(7.8731, 80.7718);
  
  bool _isUpdating = false;
  bool _showLegend = true;
  bool _isInteracting = false;
  Timer? _interactionDebounce;
  DateTime? _lastTapTime;
  LatLng? _lastTapPosition;

  bool get isUpdating => _isUpdating;
  bool get showLegend => _showLegend;
  bool get isInteracting => _isInteracting;

  // Static cache for weather attributes
  static const Map<WeatherStatus, IconData> weatherIcons = {
    WeatherStatus.sunny: Icons.wb_sunny,
    WeatherStatus.rainy: Icons.water_drop,
    WeatherStatus.cloudy: Icons.cloud,
    WeatherStatus.stormy: Icons.thunderstorm,
    WeatherStatus.flood: Icons.flood,
  };

  static const Map<WeatherStatus, Color> weatherColors = {
    WeatherStatus.sunny: Colors.orange,
    WeatherStatus.rainy: Colors.blue,
    WeatherStatus.cloudy: Colors.grey,
    WeatherStatus.stormy: Colors.purple,
    WeatherStatus.flood: Colors.red,
  };

  Stream<List<Region>> watchRegions() {
    return _repository.watchRegions().distinct((prev, next) {
      if (prev.length != next.length) return false;
      for (int i = 0; i < prev.length; i++) {
        if (prev[i].id != next[i].id ||
            prev[i].status != next[i].status ||
            prev[i].updatedAt != next[i].updatedAt) {
          return false;
        }
      }
      return true;
    });
  }

  IconData getWeatherIcon(WeatherStatus status) => weatherIcons[status]!;
  Color getWeatherColor(WeatherStatus status) => weatherColors[status]!;

  void toggleLegend() {
    _showLegend = !_showLegend;
    notifyListeners();
  }

  void setInteracting(bool value) {
    _interactionDebounce?.cancel();

    if (value) {
      if (!_isInteracting) {
        _isInteracting = true;
        notifyListeners();
      }
    } else {
      _interactionDebounce = Timer(const Duration(milliseconds: 200), () {
        if (_isInteracting) {
          _isInteracting = false;
          notifyListeners();
        }
      });
    }
  }

  void resetMapView() {
    mapController.move(sriLankaCenter, 7.5);
  }

  bool handleTapForDoubleClick(LatLng position) {
    final now = DateTime.now();
    final isDoubleTap = _lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 300 &&
        _lastTapPosition != null &&
        ((_lastTapPosition!.latitude - position.latitude).abs() < 0.01 &&
            (_lastTapPosition!.longitude - position.longitude).abs() < 0.01);

    _lastTapTime = now;
    _lastTapPosition = position;

    if (isDoubleTap) {
      // Zoom in on double tap
      final currentZoom = mapController.camera.zoom;
      if (currentZoom < 18.0) {
        mapController.move(position, currentZoom + 1);
      }
      return true;
    }
    return false;
  }

  Future<void> updateRegionStatus(
    Region region,
    WeatherStatus status,
    BuildContext context,
  ) async {
    _isUpdating = true;
    notifyListeners();

    try {
      await _repository.updateRegion(region.id, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Updated ${region.name} to ${status.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  Future<void> seedRegions(BuildContext context) async {
    try {
      await _repository.seedRegionsIfEmpty();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Regions initialized!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _interactionDebounce?.cancel();
    super.dispose();
  }
}

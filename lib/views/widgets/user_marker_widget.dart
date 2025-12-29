import 'package:flutter/material.dart';
import '../../models/user_marker.dart';
import '../../models/region.dart';

class UserMarkerWidget extends StatelessWidget {
  final UserMarker marker;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const UserMarkerWidget({
    super.key,
    required this.marker,
    required this.onTap,
    this.onDelete,
  });

  IconData _getWeatherIcon(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.sunny:
        return Icons.wb_sunny;
      case WeatherStatus.rainy:
        return Icons.water_drop;
      case WeatherStatus.cloudy:
        return Icons.cloud;
      case WeatherStatus.stormy:
        return Icons.thunderstorm;
      case WeatherStatus.flood:
        return Icons.flood;
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
      case WeatherStatus.stormy:
        return Colors.purple;
      case WeatherStatus.flood:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final weatherColor = _getWeatherColor(marker.weatherStatus);
    final weatherIcon = _getWeatherIcon(marker.weatherStatus);
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: weatherColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: weatherColor.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              weatherIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              marker.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/region.dart';
import '../../controllers/weather_controller.dart';

class RegionMarkerWidget extends StatelessWidget {
  final Region region;
  final WeatherController controller;
  final VoidCallback onTap;

  const RegionMarkerWidget({
    super.key,
    required this.region,
    required this.controller,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final weatherColor = controller.getWeatherColor(region.status);
    final weatherIcon = controller.getWeatherIcon(region.status);
    
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
              region.name,
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

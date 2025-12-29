import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/region.dart';
import '../../controllers/weather_controller.dart';

class WeatherUpdateDialog extends StatelessWidget {
  final Region region;
  final WeatherController controller;

  const WeatherUpdateDialog({
    super.key,
    required this.region,
    required this.controller,
  });

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

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Last updated: ${_formatTimeAgo(region.updatedAt)}',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
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
              _buildWeatherChip(
                context,
                WeatherStatus.sunny,
                'Sunny',
                Icons.wb_sunny,
                Colors.orange,
              ),
              _buildWeatherChip(
                context,
                WeatherStatus.rainy,
                'Rainy',
                Icons.water_drop,
                Colors.blue,
              ),
              _buildWeatherChip(
                context,
                WeatherStatus.cloudy,
                'Cloudy',
                Icons.cloud,
                Colors.grey,
              ),
              _buildWeatherChip(
                context,
                WeatherStatus.stormy,
                'Stormy',
                Icons.thunderstorm,
                Colors.purple,
              ),
              _buildWeatherChip(
                context,
                WeatherStatus.flood,
                'Flood',
                Icons.flood,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeatherChip(
    BuildContext context,
    WeatherStatus status,
    String label,
    IconData icon,
    Color color,
  ) {
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
        await controller.updateRegionStatus(region, status, context);
      },
      selectedColor: color,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

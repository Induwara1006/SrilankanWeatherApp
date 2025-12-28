import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_marker.dart';
import '../../models/region.dart';

class MarkerDetailDialog extends StatelessWidget {
  final UserMarker marker;
  final VoidCallback? onDelete;
  final Function(WeatherStatus, String)? onUpdateWeather;

  const MarkerDetailDialog({
    super.key,
    required this.marker,
    this.onDelete,
    this.onUpdateWeather,
  });

  IconData _getIconForType(MarkerType type) {
    switch (type) {
      case MarkerType.photo:
        return Icons.photo_camera;
      case MarkerType.note:
        return Icons.note;
      case MarkerType.warning:
        return Icons.warning;
      case MarkerType.event:
        return Icons.event;
      case MarkerType.place:
        return Icons.place;
    }
  }

  Color _getColorForType(MarkerType type) {
    switch (type) {
      case MarkerType.photo:
        return Colors.green;
      case MarkerType.note:
        return Colors.blue;
      case MarkerType.warning:
        return Colors.red;
      case MarkerType.event:
        return Colors.purple;
      case MarkerType.place:
        return Colors.orange;
    }
  }

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

  String _getWeatherLabel(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.sunny:
        return 'Sunny';
      case WeatherStatus.rainy:
        return 'Rainy';
      case WeatherStatus.cloudy:
        return 'Cloudy';
      case WeatherStatus.stormy:
        return 'Stormy';
      case WeatherStatus.flood:
        return 'Flood';
    }
  }

  void _showWeatherUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _WeatherUpdateDialog(
        currentStatus: marker.weatherStatus,
        onUpdate: (status, updatedBy) {
          onUpdateWeather?.call(status, updatedBy);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForType(marker.type);
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    _getIconForType(marker.type),
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          marker.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          marker.type.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (marker.description != null) ...[
                    const Row(
                      children: [
                        Icon(Icons.description, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Description',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      marker.description!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  Row(
                    children: [
                      const Icon(Icons.person, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Added by:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        marker.createdBy,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dateFormat.format(marker.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Icon(_getWeatherIcon(marker.weatherStatus), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Weather Status:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getWeatherLabel(marker.weatherStatus),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  if (marker.weatherUpdatedBy != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Updated by ${marker.weatherUpdatedBy} on ${dateFormat.format(marker.weatherUpdatedAt!)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: 12),
                  
                  if (onUpdateWeather != null)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showWeatherUpdateDialog(context),
                        icon: const Icon(Icons.edit),
                        label: const Text('Update Weather Status'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onDelete != null) ...[
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherUpdateDialog extends StatefulWidget {
  final WeatherStatus currentStatus;
  final Function(WeatherStatus, String) onUpdate;

  const _WeatherUpdateDialog({
    required this.currentStatus,
    required this.onUpdate,
  });

  @override
  State<_WeatherUpdateDialog> createState() => _WeatherUpdateDialogState();
}

class _WeatherUpdateDialogState extends State<_WeatherUpdateDialog> {
  late WeatherStatus _selectedStatus;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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

  String _getWeatherLabel(WeatherStatus status) {
    switch (status) {
      case WeatherStatus.sunny:
        return 'Sunny';
      case WeatherStatus.rainy:
        return 'Rainy';
      case WeatherStatus.cloudy:
        return 'Cloudy';
      case WeatherStatus.stormy:
        return 'Stormy';
      case WeatherStatus.flood:
        return 'Flood';
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
    return AlertDialog(
      title: const Text('Update Weather Status'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select current weather condition:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...WeatherStatus.values.map((status) {
              final isSelected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedStatus = status),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? _getWeatherColor(status)
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? _getWeatherColor(status).withOpacity(0.1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getWeatherIcon(status),
                          color: _getWeatherColor(status),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getWeatherLabel(status),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: _getWeatherColor(status),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Your Name',
                hintText: 'Anonymous',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final name =
                _nameController.text.isEmpty ? 'Anonymous' : _nameController.text;
            widget.onUpdate(_selectedStatus, name);
          },
          icon: const Icon(Icons.check),
          label: const Text('Update'),
        ),
      ],
    );
  }
}

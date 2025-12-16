import 'package:latlong2/latlong.dart';

enum WeatherStatus { sunny, rainy, cloudy, stormy, flood }

WeatherStatus statusFromString(String s) {
  switch (s) {
    case 'sunny':
      return WeatherStatus.sunny;
    case 'rainy':
      return WeatherStatus.rainy;
    case 'cloudy':
      return WeatherStatus.cloudy;
    case 'stormy':
      return WeatherStatus.stormy;
    case 'flood':
      return WeatherStatus.flood;
    default:
      return WeatherStatus.sunny;
  }
}

String statusToString(WeatherStatus status) {
  return status.toString().split('.').last;
}

class Region {
  final String id;
  final String name;
  final LatLng position;
  final WeatherStatus status;
  final DateTime updatedAt;
  final String updatedBy;

  Region({
    required this.id,
    required this.name,
    required this.position,
    required this.status,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory Region.fromFirestore(String id, Map<String, dynamic> data) {
    return Region(
      id: id,
      name: data['name'] as String,
      position: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      status: statusFromString(data['status'] as String? ?? 'sunny'),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as dynamic).toDate() 
          : DateTime.now(),
      updatedBy: data['updatedBy'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'lat': position.latitude,
      'lng': position.longitude,
      'status': statusToString(status),
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }
}

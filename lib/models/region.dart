import 'package:latlong2/latlong.dart';

enum WeatherStatus { sunny, rainy, cloudy }

WeatherStatus statusFromString(String s) {
  switch (s) {
    case 'sunny':
      return WeatherStatus.sunny;
    case 'rainy':
      return WeatherStatus.rainy;
    case 'cloudy':
      return WeatherStatus.cloudy;
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
      status: statusFromString(data['status'] as String),
      updatedAt: (data['updatedAt'] as dynamic).toDate(),
      updatedBy: data['updatedBy'] as String,
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

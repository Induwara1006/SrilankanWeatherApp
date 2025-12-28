import 'package:latlong2/latlong.dart';
import 'region.dart';

enum MarkerType {
  photo,
  note,
  warning,
  event,
  place,
}

String markerTypeToString(MarkerType type) {
  return type.toString().split('.').last;
}

MarkerType markerTypeFromString(String s) {
  switch (s) {
    case 'photo':
      return MarkerType.photo;
    case 'note':
      return MarkerType.note;
    case 'warning':
      return MarkerType.warning;
    case 'event':
      return MarkerType.event;
    case 'place':
      return MarkerType.place;
    default:
      return MarkerType.note;
  }
}

class UserMarker {
  final String id;
  final LatLng position;
  final String title;
  final String? description;
  final MarkerType type;
  final DateTime createdAt;
  final String createdBy;
  final String? photoUrl;
  final WeatherStatus weatherStatus;
  final DateTime? weatherUpdatedAt;
  final String? weatherUpdatedBy;

  UserMarker({
    required this.id,
    required this.position,
    required this.title,
    this.description,
    required this.type,
    required this.createdAt,
    required this.createdBy,
    this.photoUrl,
    this.weatherStatus = WeatherStatus.sunny,
    this.weatherUpdatedAt,
    this.weatherUpdatedBy,
  });

  factory UserMarker.fromFirestore(String id, Map<String, dynamic> data) {
    return UserMarker(
      id: id,
      position: LatLng(
        (data['lat'] as num).toDouble(),
        (data['lng'] as num).toDouble(),
      ),
      title: data['title'] as String,
      description: data['description'] as String?,
      type: markerTypeFromString(data['type'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      createdBy: data['createdBy'] as String,
      photoUrl: data['photoUrl'] as String?,
      weatherStatus: data['weatherStatus'] != null 
          ? statusFromString(data['weatherStatus'] as String)
          : WeatherStatus.sunny,
      weatherUpdatedAt: data['weatherUpdatedAt'] != null
          ? DateTime.parse(data['weatherUpdatedAt'] as String)
          : null,
      weatherUpdatedBy: data['weatherUpdatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'title': title,
      'description': description,
      'type': markerTypeToString(type),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'photoUrl': photoUrl,
      'weatherStatus': statusToString(weatherStatus),
      'weatherUpdatedAt': weatherUpdatedAt?.toIso8601String(),
      'weatherUpdatedBy': weatherUpdatedBy,
    };
  }
}

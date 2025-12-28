import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_marker.dart';

class UserMarkerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'user_markers';

  Stream<List<UserMarker>> watchUserMarkers() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserMarker.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addMarker(UserMarker marker) async {
    await _firestore.collection(_collection).add(marker.toFirestore());
  }

  Future<void> deleteMarker(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  Future<void> updateMarker(String id, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(id).update(data);
  }

  Future<void> updateWeatherStatus(
    String markerId,
    String status,
    String updatedBy,
  ) async {
    await _firestore.collection(_collection).doc(markerId).update({
      'weatherStatus': status,
      'weatherUpdatedAt': DateTime.now().toIso8601String(),
      'weatherUpdatedBy': updatedBy,
    });
  }
}

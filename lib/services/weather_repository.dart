import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';
import '../models/region.dart';

class WeatherRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Region>> watchRegions() {
    return _firestore.collection('regions').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Region.fromFirestore(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> updateRegion(String regionId, WeatherStatus status) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _firestore.collection('regions').doc(regionId).update({
      'status': statusToString(status),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user.uid,
    });
  }

  Future<void> seedRegionsIfEmpty() async {
    final snapshot = await _firestore.collection('regions').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final regions = [
      {'id': 'colombo', 'name': 'Colombo', 'lat': 6.9271, 'lng': 79.8612},
      {'id': 'gampaha', 'name': 'Gampaha', 'lat': 7.0873, 'lng': 79.9946},
      {'id': 'kalutara', 'name': 'Kalutara', 'lat': 6.5854, 'lng': 79.9607},
      {'id': 'kandy', 'name': 'Kandy', 'lat': 7.2906, 'lng': 80.6337},
      {'id': 'matale', 'name': 'Matale', 'lat': 7.4675, 'lng': 80.6234},
      {'id': 'nuwara-eliya', 'name': 'Nuwara Eliya', 'lat': 6.9497, 'lng': 80.7891},
      {'id': 'galle', 'name': 'Galle', 'lat': 6.0535, 'lng': 80.2210},
      {'id': 'matara', 'name': 'Matara', 'lat': 5.9549, 'lng': 80.5550},
      {'id': 'hambantota', 'name': 'Hambantota', 'lat': 6.1429, 'lng': 81.1212},
      {'id': 'jaffna', 'name': 'Jaffna', 'lat': 9.6615, 'lng': 80.0255},
      {'id': 'kilinochchi', 'name': 'Kilinochchi', 'lat': 9.3833, 'lng': 80.4000},
      {'id': 'mannar', 'name': 'Mannar', 'lat': 8.9810, 'lng': 79.9044},
      {'id': 'vavuniya', 'name': 'Vavuniya', 'lat': 8.7542, 'lng': 80.4982},
      {'id': 'mullaitivu', 'name': 'Mullaitivu', 'lat': 9.2671, 'lng': 80.8142},
      {'id': 'batticaloa', 'name': 'Batticaloa', 'lat': 7.7310, 'lng': 81.6747},
      {'id': 'ampara', 'name': 'Ampara', 'lat': 7.2914, 'lng': 81.6747},
      {'id': 'trincomalee', 'name': 'Trincomalee', 'lat': 8.5874, 'lng': 81.2152},
      {'id': 'kurunegala', 'name': 'Kurunegala', 'lat': 7.4818, 'lng': 80.3609},
      {'id': 'puttalam', 'name': 'Puttalam', 'lat': 8.0362, 'lng': 79.8283},
      {'id': 'anuradhapura', 'name': 'Anuradhapura', 'lat': 8.3114, 'lng': 80.4037},
      {'id': 'polonnaruwa', 'name': 'Polonnaruwa', 'lat': 7.9403, 'lng': 81.0188},
      {'id': 'badulla', 'name': 'Badulla', 'lat': 6.9934, 'lng': 81.0550},
      {'id': 'moneragala', 'name': 'Moneragala', 'lat': 6.8728, 'lng': 81.3507},
      {'id': 'ratnapura', 'name': 'Ratnapura', 'lat': 6.6828, 'lng': 80.3992},
      {'id': 'kegalle', 'name': 'Kegalle', 'lat': 7.2513, 'lng': 80.3464},
    ];

    final batch = _firestore.batch();
    for (final r in regions) {
      final docRef = _firestore.collection('regions').doc(r['id'] as String);
      batch.set(docRef, {
        'name': r['name'],
        'lat': r['lat'],
        'lng': r['lng'],
        'status': 'sunny',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
      });
    }
    await batch.commit();
  }
}

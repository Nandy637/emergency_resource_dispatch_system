// ============================================================
// service: firebase_service.dart
// All Firestore read / write operations for the SafeCall SOS app.
// Collections used:
//   • emergencies  — SOS requests
//   • responders   — unit registry
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/emergency.dart';
import '../models/responder.dart';

class FirebaseService {
  // ── singleton ────────────────────────────────────────────
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  final _db = FirebaseFirestore.instance;

  // ── collection references ─────────────────────────────────
  CollectionReference<Map<String, dynamic>> get _emergencies =>
      _db.collection('emergencies');

  CollectionReference<Map<String, dynamic>> get _responders =>
      _db.collection('responders');

  // ════════════════════════════════════════════════════════
  //  EMERGENCY  operations
  // ════════════════════════════════════════════════════════

  /// Create a new SOS document. Returns the auto-generated Firestore doc ID.
  Future<String> createEmergency(Emergency emergency) async {
    final docRef = await _emergencies.add(emergency.toMap());
    return docRef.id;
  }

  /// Real-time stream of a single emergency (user tracking screen).
  Stream<Emergency> listenToEmergency(String id) {
    return _emergencies.doc(id).snapshots().map(
          (snap) => Emergency.fromFirestore(snap),
        );
  }

  /// Stream of pending emergencies filtered by type (responder dashboard).
  /// NOTE: orderBy is intentionally omitted to avoid requiring a Firestore
  /// composite index. Results are sorted client-side by timestamp.
  Stream<List<Emergency>> listenToNewEmergencies(String type) {
    return _emergencies
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => Emergency.fromFirestore(d))
          .toList();
      // Sort client-side: newest first
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  /// Update only the status field of an emergency document.
  Future<void> updateEmergencyStatus(String id, EmergencyStatus status) async {
    await _emergencies.doc(id).update({'status': status.name});
  }

  /// Write the responder's live GeoPoint into the emergency document.
  Future<void> updateResponderLocationOnEmergency(
    String emergencyId,
    GeoPoint location,
  ) async {
    await _emergencies.doc(emergencyId).update({
      'responder_location': location,
    });
  }

  /// Write Directions API result (ETA + route polyline) to the emergency doc.
  Future<void> updateRouteData({
    required String emergencyId,
    required int etaSeconds,
    required String encodedPolyline,
  }) async {
    await _emergencies.doc(emergencyId).update({
      'eta_seconds': etaSeconds,
      'route_polyline': encodedPolyline,
    });
  }

  /// Assign a responder to an emergency (atomic update).
  Future<void> assignResponder(String emergencyId, String responderId) async {
    await _emergencies.doc(emergencyId).update({
      'responder_id': responderId,
      'status': EmergencyStatus.assigned.name,
    });
  }

  // ════════════════════════════════════════════════════════
  //  RESPONDER  operations
  // ════════════════════════════════════════════════════════

  /// Fetch all responders that are available AND of a given type.
  Future<List<Responder>> getAvailableResponders(String type) async {
    final snap = await _responders
        .where('type', isEqualTo: type)
        .where('status', isEqualTo: 'available')
        .get();
    return snap.docs.map((d) => Responder.fromFirestore(d)).toList();
  }

  /// Update a responder's status (available / busy / offline).
  /// Uses set+merge so the document is created if it doesn't exist yet.
  Future<void> setResponderStatus(String id, ResponderStatus status) async {
    await _responders.doc(id).set(
      {'status': status.name},
      SetOptions(merge: true),
    );
  }

  /// Update a responder's live location in the responders collection.
  /// Uses set+merge so the document is created if it doesn't exist yet.
  Future<void> updateResponderLocation(
      String responderId, GeoPoint location) async {
    await _responders.doc(responderId).set(
      {'location': location},
      SetOptions(merge: true),
    );
  }

  /// Seed a responder document for development/testing.
  /// Call this once manually from a dev screen or unit test.
  Future<void> seedResponder(Responder responder) async {
    await _responders.doc(responder.id).set(responder.toMap());
  }
}

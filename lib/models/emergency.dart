// ============================================================
// model: emergency.dart
// Represents a single SOS emergency request document in Firestore.
// Collection: emergencies/{id}
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Possible lifecycle states of an emergency.
enum EmergencyStatus {
  pending,    // Created, no responder yet
  assigned,   // Responder nominated, not yet en route
  onTheWay,   // Responder accepted and moving
  arrived,    // Responder reached the scene
  completed,  // Incident resolved
}

/// Type of emergency selected by the citizen.
enum EmergencyType { medical, fire, police }

// ── helpers ──────────────────────────────────────────────────

extension EmergencyStatusX on EmergencyStatus {
  String get label {
    switch (this) {
      case EmergencyStatus.pending:   return 'Pending';
      case EmergencyStatus.assigned:  return 'Assigned';
      case EmergencyStatus.onTheWay:  return 'On the Way';
      case EmergencyStatus.arrived:   return 'Arrived';
      case EmergencyStatus.completed: return 'Completed';
    }
  }

  static EmergencyStatus fromString(String s) {
    switch (s) {
      case 'assigned':  return EmergencyStatus.assigned;
      case 'onTheWay':  return EmergencyStatus.onTheWay;
      case 'arrived':   return EmergencyStatus.arrived;
      case 'completed': return EmergencyStatus.completed;
      default:          return EmergencyStatus.pending;
    }
  }
}

extension EmergencyTypeX on EmergencyType {
  String get name {
    switch (this) {
      case EmergencyType.medical: return 'medical';
      case EmergencyType.fire:    return 'fire';
      case EmergencyType.police:  return 'police';
    }
  }

  String get emoji {
    switch (this) {
      case EmergencyType.medical: return '🏥';
      case EmergencyType.fire:    return '🔥';
      case EmergencyType.police:  return '🚔';
    }
  }

  static EmergencyType fromString(String s) {
    switch (s) {
      case 'fire':   return EmergencyType.fire;
      case 'police': return EmergencyType.police;
      default:       return EmergencyType.medical;
    }
  }
}

// ── model ─────────────────────────────────────────────────────

class Emergency {
  final String id;
  final EmergencyType type;
  final GeoPoint userLocation;
  final GeoPoint? responderLocation;
  final EmergencyStatus status;
  final String? responderId;
  final Timestamp timestamp;
  final String? contactPhone; // family alert target
  final int? etaSeconds;      // Directions API drive-time in seconds
  final String? routePolyline; // Google-encoded polyline for fastest route

  const Emergency({
    required this.id,
    required this.type,
    required this.userLocation,
    this.responderLocation,
    required this.status,
    this.responderId,
    required this.timestamp,
    this.contactPhone,
    this.etaSeconds,
    this.routePolyline,
  });

  /// Build from a Firestore document snapshot.
  factory Emergency.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Emergency(
      id: doc.id,
      type: EmergencyTypeX.fromString(data['type'] as String? ?? 'medical'),
      userLocation: data['user_location'] as GeoPoint,
      responderLocation: data['responder_location'] as GeoPoint?,
      status: EmergencyStatusX.fromString(data['status'] as String? ?? 'pending'),
      responderId: data['responder_id'] as String?,
      timestamp: data['timestamp'] as Timestamp? ?? Timestamp.now(),
      contactPhone: data['contact_phone'] as String?,
      etaSeconds: data['eta_seconds'] as int?,
      routePolyline: data['route_polyline'] as String?,
    );
  }

  /// Serialise to a Firestore-compatible map.
  Map<String, dynamic> toMap() => {
    'type': type.name,
    'user_location': userLocation,
    'responder_location': responderLocation,
    'status': status.name,
    'responder_id': responderId,
    'timestamp': timestamp,
    'contact_phone': contactPhone,
    'eta_seconds': etaSeconds,
    'route_polyline': routePolyline,
  };

  Emergency copyWith({
    EmergencyStatus? status,
    GeoPoint? responderLocation,
    String? responderId,
    int? etaSeconds,
    String? routePolyline,
  }) =>
      Emergency(
        id: id,
        type: type,
        userLocation: userLocation,
        responderLocation: responderLocation ?? this.responderLocation,
        status: status ?? this.status,
        responderId: responderId ?? this.responderId,
        timestamp: timestamp,
        contactPhone: contactPhone,
        etaSeconds: etaSeconds ?? this.etaSeconds,
        routePolyline: routePolyline ?? this.routePolyline,
      );
}

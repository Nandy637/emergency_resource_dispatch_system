// ============================================================
// model: responder.dart
// Represents a first-responder unit document in Firestore.
// Collection: responders/{id}
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

/// Availability state of a responder unit.
enum ResponderStatus { available, busy, offline }

/// Type of responder unit.
enum ResponderType { ambulance, fire, police }

// ── helpers ──────────────────────────────────────────────────

extension ResponderStatusX on ResponderStatus {
  String get name {
    switch (this) {
      case ResponderStatus.available: return 'available';
      case ResponderStatus.busy:      return 'busy';
      case ResponderStatus.offline:   return 'offline';
    }
  }

  static ResponderStatus fromString(String s) {
    switch (s) {
      case 'busy':    return ResponderStatus.busy;
      case 'offline': return ResponderStatus.offline;
      default:        return ResponderStatus.available;
    }
  }
}

extension ResponderTypeX on ResponderType {
  String get name {
    switch (this) {
      case ResponderType.ambulance: return 'ambulance';
      case ResponderType.fire:      return 'fire';
      case ResponderType.police:    return 'police';
    }
  }

  String get emoji {
    switch (this) {
      case ResponderType.ambulance: return '🚑';
      case ResponderType.fire:      return '🚒';
      case ResponderType.police:    return '🚓';
    }
  }

  // Map emergency type string → responder type
  static ResponderType fromEmergencyType(String emergencyType) {
    switch (emergencyType) {
      case 'fire':   return ResponderType.fire;
      case 'police': return ResponderType.police;
      default:       return ResponderType.ambulance;
    }
  }

  static ResponderType fromString(String s) {
    switch (s) {
      case 'fire':   return ResponderType.fire;
      case 'police': return ResponderType.police;
      default:       return ResponderType.ambulance;
    }
  }
}

// ── model ─────────────────────────────────────────────────────

class Responder {
  final String id;
  final ResponderType type;
  final ResponderStatus status;
  final GeoPoint location;

  const Responder({
    required this.id,
    required this.type,
    required this.status,
    required this.location,
  });

  factory Responder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Responder(
      id: doc.id,
      type: ResponderTypeX.fromString(data['type'] as String? ?? 'ambulance'),
      status: ResponderStatusX.fromString(data['status'] as String? ?? 'available'),
      location: data['location'] as GeoPoint,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.name,
    'status': status.name,
    'location': location,
  };
}

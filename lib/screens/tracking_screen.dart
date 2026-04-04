import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' show PlatformDispatcher;
import 'dart:convert';
import 'package:http/http.dart' as http;

const String _baseUrl = 'http://192.168.31.25:8000/api/v1';

/// Emergency numbers by region/country
/// US: 911, EU/UK: 112, AU: 000, JP: 110
const Map<String, String> kEmergencyNumbers = {
  'US': '911',
  'CA': '911',
  'GB': '999',
  'IE': '999',
  'DE': '112',
  'FR': '112',
  'IT': '112',
  'ES': '112',
  'NL': '112',
  'BE': '112',
  'AT': '112',
  'CH': '112',
  'AU': '000',
  'JP': '110',
  'IN': '112',
};

/// Get emergency number based on device locale
String _getEmergencyNumber() {
  // Try to get device locale
  final locale = PlatformDispatcher.instance.locale;
  final countryCode = locale.countryCode ?? 'US';
  
  // Check for known emergency number mappings
  return kEmergencyNumbers[countryCode] ?? '112'; // Default to 112 (international)
}

/// Default emergency number constant for reference
const String kEmergencyNumber = '911';

/// Incident Tracking Screen
/// Displays live map and responder details after SOS is triggered
class TrackingScreen extends StatefulWidget {
  final String incidentId;
  final Position? userLocation;
  
  const TrackingScreen({
    Key? key,
    required this.incidentId,
    this.userLocation,
  }) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  
  List<Map<String, dynamic>> _responders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTrackingData();
  }

  Future<void> _fetchTrackingData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/incident/${widget.incidentId}/tracking'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final respondersList = data['responders'] as List;
        setState(() {
          _responders = respondersList.map((r) => {
            'name': r['name'],
            'type': r['type'],
            'eta': r['eta'],
            'distance': r['distance'],
            'status': r['status'],
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        elevation: 0,
        title: Text(
          'Incident Tracking',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone, color: Colors.white),
            onPressed: () async {
              final String emergencyNumber = _getEmergencyNumber();
              final Uri emergencyUrl = Uri(scheme: 'tel', path: emergencyNumber);
              if (await canLaunchUrl(emergencyUrl)) {
                await launchUrl(emergencyUrl);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not launch emergency dialer')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Incident Status Header
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.red[50],
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOS Activated',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      Text(
                        'Incident #${widget.incidentId}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (widget.userLocation != null)
                        Text(
                          'Location: ${widget.userLocation!.latitude.toStringAsFixed(4)}, ${widget.userLocation!.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Map View - shows Google Maps if location available, else placeholder
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.userLocation != null
                  ? _buildGoogleMap()
                  : _buildMapPlaceholder(),
            ),
          ),

          // Responders List
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Responders Dispatched',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_responders.length} units',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _responders.length,
                      itemBuilder: (context, index) {
                        final responder = _responders[index];
                        return _buildResponderCard(responder);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponderCard(Map<String, dynamic> responder) {
    final bool isArrived = responder['status'] == 'Arrived';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isArrived ? Colors.green : Colors.grey[200]!,
          width: isArrived ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Responder Type Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getResponderColor(responder['type']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getResponderIcon(responder['type']),
              color: _getResponderColor(responder['type']),
            ),
          ),
          SizedBox(width: 16),
          // Responder Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  responder['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${responder['eta']} away',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    SizedBox(width: 4),
                    Text(
                      responder['distance'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isArrived ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              responder['status'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getResponderColor(String type) {
    switch (type) {
      case 'Medical':
        return Colors.red;
      case 'Fire':
        return Colors.orange;
      case 'Police':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getResponderIcon(String type) {
    switch (type) {
      case 'Medical':
        return Icons.medical_services;
      case 'Fire':
        return Icons.local_fire_department;
      case 'Police':
        return Icons.local_police;
      default:
        return Icons.directions_car;
    }
  }

  /// Build Google Maps widget with user location
  Widget _buildGoogleMap() {
    final LatLng userLatLng = LatLng(
      widget.userLocation!.latitude,
      widget.userLocation!.longitude,
    );

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: userLatLng,
        zoom: 15,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      markers: {
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLatLng,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      },
    );
  }

  /// Build placeholder when location is unavailable
  Widget _buildMapPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 12),
          Text(
            'Live Map View',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
          Text(
            'Google Maps / MapKit Integration',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

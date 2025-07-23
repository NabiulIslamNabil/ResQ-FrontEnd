// Enhanced UI with Traffic Insights
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;



class MapPageForPoliceStation extends StatefulWidget {
  const MapPageForPoliceStation({super.key});

  @override
  _MapPageForPoliceStationState createState() => _MapPageForPoliceStationState();
}

class _MapPageForPoliceStationState extends State<MapPageForPoliceStation> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _fireStation = LatLng(23.797883, 90.424082);
  final LatLng _university = LatLng(23.797354, 90.449651);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  double _currentZoom = 14;
  final bool _trafficEnabled = true;
  String _trafficStatus = "Checking...";
  List<String> _trafficMessages = [];

  static const String _apiKey = 'AIzaSyA3cWz0lTMFXHrVHB10SCkL0cRJ7AuaAT0';

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    _addMarkers();
    await _drawRoute();
  }

  void _addMarkers() {
    setState(() {
      _markers.add(Marker(markerId: MarkerId('fireStation'), position: _fireStation));
      _markers.add(Marker(markerId: MarkerId('university'), position: _university));
    });
  }

  Future<void> _drawRoute() async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_fireStation.latitude},${_fireStation.longitude}&destination=${_university.latitude},${_university.longitude}&departure_time=now&key=$_apiKey',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'] as List;
      if (routes.isNotEmpty) {
        final overviewPoints = _decodePolyline(routes[0]['overview_polyline']['points']);
        final legs = routes[0]['legs'] as List;
        List<String> messages = [];

        for (var leg in legs) {
          for (var step in leg['steps']) {
            final instruction = step['html_instructions']?.replaceAll(RegExp(r'<[^>]*>'), '') ?? 'Road segment';
            final duration = step['duration']['text'] ?? '';
            messages.add('$instruction ➜ Estimated time: $duration');
          }
        }

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: overviewPoints,
            color: Colors.redAccent,
            width: 5,
          ));
          _trafficStatus = "Live Traffic Insights";
          _trafficMessages = messages;
        });
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polylineCoordinates;
  }

  Future<void> _zoomMap(bool zoomIn) async {
    final controller = await _controller.future;
    _currentZoom += zoomIn ? 1 : -1;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: _fireStation, zoom: _currentZoom),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _fireStation,
              zoom: _currentZoom,
            ),
            markers: _markers,
            polylines: _polylines,
            trafficEnabled: _trafficEnabled,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  onPressed: () => _zoomMap(true),
                  mini: true,
                  child: Icon(Icons.zoom_in),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  onPressed: () => _zoomMap(false),
                  mini: true,
                  child: Icon(Icons.zoom_out),
                ),
              ],
            ),
          ),
          Positioned(
            top: 120,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 Crowd Control Request from Notun Bazar Fire Station',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _trafficStatus,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    Divider(),
                    ..._trafficMessages.map((msg) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Text(
                            '• $msg',
                            style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

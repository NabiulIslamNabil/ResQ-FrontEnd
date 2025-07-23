import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;



class MapPageForFireStation extends StatefulWidget {
  const MapPageForFireStation({super.key});

  @override
  _MapPageForFireStationState createState() => _MapPageForFireStationState();
}

class _MapPageForFireStationState extends State<MapPageForFireStation> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _fireStation = LatLng(23.797883, 90.424082);
  final LatLng _university = LatLng(23.797354, 90.449651);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  final Set<Polygon> _polygons = {};
  bool _trafficEnabled = true;
  double _currentZoom = 14;
  String _trafficStatus = "Unknown";

  static const String _apiKey = 'AIzaSyA3cWz0lTMFXHrVHB10SCkL0cRJ7AuaAT0';

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    await _addMarkers();
    await _drawRoute();
    await _markRedZone();
    await _markWaterZones();
    await _fetchTrafficStatus();
  }

  Future<void> _addMarkers() async {
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
        final points = _decodePolyline(routes[0]['overview_polyline']['points']);
        final summary = routes[0]['legs'][0]['duration_in_traffic']['text'];

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: points,
            color: Colors.redAccent,
            width: 5,
          ));
          _trafficStatus = summary;
        });
      } else {
        print('No routes found');
      }
    } else {
      print('Failed to load directions: ${response.body}');
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

  Future<void> _markRedZone() async {
    setState(() {
      _circles.add(Circle(
        circleId: CircleId('redZone'),
        center: _university,
        radius: 150,
        strokeColor: Colors.red,
        strokeWidth: 2,
        fillColor: Colors.red.withOpacity(0.3),
      ));
    });
  }

  Future<void> _markWaterZones() async {
    setState(() {
      final waterSpots = [
        LatLng(23.7969, 90.4480),
        LatLng(23.7971, 90.4492),
        LatLng(23.7975, 90.4498),
        LatLng(23.7973, 90.4501),
        LatLng(23.7967, 90.4488),
      ];

      for (int i = 0; i < waterSpots.length; i++) {
        _markers.add(Marker(
          markerId: MarkerId('water$i'),
          position: waterSpots[i],
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Water Source ${i + 1}'),
        ));
      }
    });
  }

  Future<void> _fetchTrafficStatus() async {
    await _drawRoute();
  }

  void _notifyEmergencyTeams() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Police and Volunteer Teams Notified!')),
    );
  }

  void _toggleTraffic() {
    setState(() {
      _trafficEnabled = !_trafficEnabled;
    });
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
            trafficEnabled: _trafficEnabled,
            markers: _markers,
            circles: _circles,
            polygons: _polygons,
            polylines: _polylines,
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
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'toggleTraffic',
                  onPressed: () => _toggleTraffic(),
                  mini: true,
                  backgroundColor: Colors.purple,
                  child: Icon(Icons.traffic),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: _fetchTrafficStatus,
                  child: Text("Traffic: $_trafficStatus"),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 240, 235, 235),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              icon: Icon(Icons.warning, size: 24),
              label: Text('Emergency: Notify Police & Volunteers', style: TextStyle(fontSize: 16)),
              onPressed: _notifyEmergencyTeams,
            ),
          ),
        ],
      ),
    );
  }
}

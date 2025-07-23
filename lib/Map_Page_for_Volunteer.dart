import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;



class MapPageForVolunteer extends StatefulWidget {
  const MapPageForVolunteer({super.key});

  @override
  _MapPageForVolunteerState createState() => _MapPageForVolunteerState();
}

class _MapPageForVolunteerState extends State<MapPageForVolunteer> {
  final Completer<GoogleMapController> _controller = Completer();
  final LatLng _fireStation = LatLng(23.797883, 90.424082);
  final LatLng _university = LatLng(23.797354, 90.449651);
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  final double _currentZoom = 14;
  static const String _apiKey = 'AIzaSyA3cWz0lTMFXHrVHB10SCkL0cRJ7AuaAT0';
  final Map<String, bool> _informedHospitals = {};

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    _addMarkers();
    _drawRedZone();
    await _drawRoute();
    await _loadNearbyHospitals();
  }

  void _addMarkers() {
    setState(() {
      _markers.add(Marker(markerId: MarkerId('fireStation'), position: _fireStation));
      _markers.add(Marker(markerId: MarkerId('university'), position: _university));
    });
  }

  void _drawRedZone() {
    setState(() {
      _circles.add(Circle(
        circleId: CircleId('redZone'),
        center: _university,
        radius: 600,
        fillColor: Colors.red.withOpacity(0.2),
        strokeColor: Colors.red,
        strokeWidth: 2,
      ));
    });
  }

  Future<void> _drawRoute() async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${_fireStation.latitude},${_fireStation.longitude}&destination=${_university.latitude},${_university.longitude}&key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final points = _decodePolyline(data['routes'][0]['overview_polyline']['points']);
      setState(() {
        _polylines.add(Polyline(
          polylineId: PolylineId('route'),
          points: points,
          color: Colors.redAccent,
          width: 5,
        ));
      });
    }
  }

  Future<void> _loadNearbyHospitals() async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${_university.latitude},${_university.longitude}&radius=1500&type=hospital&key=$_apiKey',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hospitals = data['results'] as List;
      for (int i = 0; i < hospitals.length && i < 5; i++) {
        final hospital = hospitals[i];
        final lat = hospital['geometry']['location']['lat'];
        final lng = hospital['geometry']['location']['lng'];
        final name = hospital['name'];
        final address = hospital['vicinity'];
        final placeId = hospital['place_id'];

        _informedHospitals[placeId] = false;

        _markers.add(Marker(
          markerId: MarkerId(placeId),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () => _showHospitalDetails(placeId, name, address),
        ));
      }
      setState(() {});
    }
  }

  void _showHospitalDetails(String id, String name, String address) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isInformed = _informedHospitals[id] ?? false;
        return AlertDialog(
          title: Text(name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Address: $address"),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInformed ? const Color.fromARGB(255, 253, 254, 253) : const Color.fromARGB(255, 244, 241, 241),
                ),
                child: Text(isInformed ? "Informed" : "Inform This Hospital"),
                onPressed: () {
                  setState(() {
                    _informedHospitals[id] = true;
                  });
                  Navigator.of(ctx).pop();
                },
              )
            ],
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _fireStation, zoom: _currentZoom),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            onMapCreated: (controller) => _controller.complete(controller),
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              color: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '🚑 A Request For First AID and Medical Service From Notun Bazar Fire Station',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// Fully loaded MapPage.dart with improved hospital detection
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  final LatLng? initialLocation;
  
  const MapPage({super.key, this.initialLocation});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _location = Location();
  GoogleMapController? _mapController;
  LatLng? _current;
  LatLng? _tapped;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _follow = true;
  bool _fabExpanded = false;

  final placesApiKey = 'AIzaSyA3cWz0lTMFXHrVHB10SCkL0cRJ7AuaAT0';
  final directionsApiKey = 'AIzaSyA3cWz0lTMFXHrVHB10SCkL0cRJ7AuaAT0';

  @override
  void initState() {
    super.initState();
    _trackLocation();
    
    // If initialLocation is provided, update the camera position
    if (widget.initialLocation != null) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(widget.initialLocation!, 15),
          );
          
          // Also add a marker at this location
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId('destination'),
                position: widget.initialLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: InfoWindow(
                  title: 'Emergency Location',
                ),
              ),
            );
          });
        }
      });
    }
  }

  Future<void> _trackLocation() async {
    if (await _location.hasPermission() == PermissionStatus.denied) {
      await _location.requestPermission();
    }
    if (!await _location.serviceEnabled()) {
      if (!await _location.requestService()) return;
    }
    final loc = await _location.getLocation();
    _updatePosition(loc.latitude!, loc.longitude!);

    _location.onLocationChanged.listen((loc) {
      if (_follow) {
        _updatePosition(loc.latitude!, loc.longitude!);
      }
    });
  }

  void _updatePosition(double lat, double lng) {
    final pos = LatLng(lat, lng);
    setState(() {
      _current = pos;
      _addOrUpdateMarker(
        "user",
        pos,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        "You are here",
      );
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  void _addOrUpdateMarker(
    String id,
    LatLng pos,
    BitmapDescriptor icon,
    String title, {
    String? placeId,
  }) {
    _markers.removeWhere((m) => m.markerId.value == id);
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: pos,
        icon: icon,
        infoWindow: InfoWindow(
          title: title,
          onTap: placeId != null ? () => _fetchPlaceDetails(placeId) : null,
        ),
      ),
    );
  }

  Future<void> _fetchPlaceDetails(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId&key=$placesApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['status'] != 'OK') {
      _showError('Failed to fetch details.');
      return;
    }

    final result = data['result'];
    final name = result['name'] ?? 'Unknown';
    final address = result['formatted_address'] ?? 'No address available';
    final phone = result['formatted_phone_number'] ?? 'No phone';
    final rating = result['rating']?.toString() ?? 'No rating';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(name),
            content: Text('Address: $address\nPhone: $phone\nRating: $rating'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  double _calculateDistance(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180.0;
    final dLng = (b.longitude - a.longitude) * pi / 180.0;
    final lat1 = a.latitude * pi / 180.0;
    final lat2 = b.latitude * pi / 180.0;
    final aHarv =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(aHarv), sqrt(1 - aHarv));
    return earthRadius * c;
  }

  Future<void> _findNearestFireStation() async {
    await _findNearestAccurate(
      'Fire Service and Civil Defence Station',
      Colors.deepOrange,
    );
  }

  Future<void> _findNearestFamousHospital() async {
    if (_current == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_current!.latitude},${_current!.longitude}'
        '&radius=1000'
        '&keyword=hospital'
        '&key=$placesApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['status'] != 'OK' || data['results'].isEmpty) {
      _showError('No nearby hospitals found.');
      return;
    }

    var nearest = data['results'][0];
    double minDistance = double.infinity;
    for (var result in data['results']) {
      final types = result['types'] as List<dynamic>? ?? [];
      final name = result['name']?.toString().toLowerCase() ?? '';
      if (!types.contains('hospital')) continue;
      if (!(name.contains('hospital') ||
          name.contains('clinic') ||
          name.contains('medical'))) {
        continue;
      }

      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];
      final dist = _calculateDistance(_current!, LatLng(lat, lng));

      if (dist < minDistance) {
        minDistance = dist;
        nearest = result;
      }
    }

    final lat = nearest['geometry']['location']['lat'];
    final lng = nearest['geometry']['location']['lng'];
    final name = nearest['name'];
    final pos = LatLng(lat, lng);
    final placeId = nearest['place_id'];

    final route = await _getRoute(_current!, pos);
    if (route == null) {
      _showError('Route to $name failed.');
      return;
    }

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('hospital-route'),
          points: route,
          width: 5,
          color: Colors.red,
        ),
      );
      _addOrUpdateMarker(
        'hospital',
        pos,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        name,
        placeId: placeId,
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_getBounds(_current!, pos), 80),
    );
  }

  Future<void> _findNearestAccurate(String keyword, Color lineColor) async {
    if (_current == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_current!.latitude},${_current!.longitude}'
        '&radius=8000'
        '&keyword=${Uri.encodeComponent(keyword)}'
        '&key=$placesApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['status'] != 'OK' || data['results'].isEmpty) {
      _showError('No nearby $keyword found.');
      return;
    }

    var nearest = data['results'][0];
    double minDistance = double.infinity;
    for (var result in data['results']) {
      final lat = result['geometry']['location']['lat'];
      final lng = result['geometry']['location']['lng'];
      final dist = _calculateDistance(_current!, LatLng(lat, lng));
      if (dist < minDistance) {
        minDistance = dist;
        nearest = result;
      }
    }

    final lat = nearest['geometry']['location']['lat'];
    final lng = nearest['geometry']['location']['lng'];
    final name = nearest['name'];
    final pos = LatLng(lat, lng);
    final placeId = nearest['place_id'];

    final route = await _getRoute(_current!, pos);
    if (route == null) {
      _showError('Route to $name failed.');
      return;
    }

    setState(() {
      _polylines.clear();
      _polylines.add(
        Polyline(
          polylineId: PolylineId('$keyword-route'),
          points: route,
          width: 5,
          color: lineColor,
        ),
      );
      _addOrUpdateMarker(
        keyword,
        pos,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        name,
        placeId: placeId,
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(_getBounds(_current!, pos), 80),
    );
  }

  Future<List<LatLng>?> _getRoute(LatLng start, LatLng end) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${start.latitude},${start.longitude}'
        '&destination=${end.latitude},${end.longitude}'
        '&key=$directionsApiKey';

    final res = await http.get(Uri.parse(url));
    final data = json.decode(res.body);

    if (data['status'] != 'OK') return null;

    final points = data['routes'][0]['overview_polyline']['points'];
    return _decode(points);
  }

  List<LatLng> _decode(String encoded) {
    List<LatLng> poly = [];
    int index = 0, lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }

  LatLngBounds _getBounds(LatLng p1, LatLng p2) {
    return LatLngBounds(
      southwest: LatLng(
        [p1.latitude, p2.latitude].reduce(min),
        [p1.longitude, p2.longitude].reduce(min),
      ),
      northeast: LatLng(
        [p1.latitude, p2.latitude].reduce(max),
        [p1.longitude, p2.longitude].reduce(max),
      ),
    );
  }

  void _addCustomMarker(String type, BitmapDescriptor icon) {
    if (_tapped == null) return;
    final id = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    final marker = Marker(
      markerId: MarkerId(id),
      position: _tapped!,
      icon: icon,
      infoWindow: InfoWindow(
        title: type.replaceAll('_', ' ').toUpperCase(),
        onTap: () => _showMarkerOptionsDialog(type),
      ),
    );
    setState(() => _markers.add(marker));
  }

  void _showMarkerOptionsDialog(String type) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text("Report $type"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text("Too much Water"),
                  value: false,
                  onChanged: (_) {},
                ),
                CheckboxListTile(
                  title: const Text("Little amount of water"),
                  value: false,
                  onChanged: (_) {},
                ),
                CheckboxListTile(
                  title: const Text("Previously Used?"),
                  value: false,
                  onChanged: (_) {},
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(23.8103, 90.4125),
              zoom: 12,
            ),
            onMapCreated: (c) => _mapController = c,
            onTap: (pos) => setState(() => _tapped = pos),
            onCameraMoveStarted: () => _follow = false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(Colors.white70),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: Column(
              children: [
                _fab(_fabExpanded ? Icons.close : Icons.menu, () {
                  setState(() => _fabExpanded = !_fabExpanded);
                }),
                if (_fabExpanded) ...[
                  _fab(Icons.my_location, () {
                    _follow = true;
                    if (_current != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_current!, 15),
                      );
                    }
                  }),
                  _fab(Icons.local_hospital, _findNearestFamousHospital),
                  _fab(Icons.local_fire_department, _findNearestFireStation),
                  _fab(
                    Icons.water_drop,
                    () => _addCustomMarker(
                      'water_source',
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueCyan,
                      ),
                    ),
                  ),
                  _fab(
                    Icons.warning,
                    () => _addCustomMarker(
                      'danger_zone',
                      BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueOrange,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fab(IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: FloatingActionButton.small(
      backgroundColor: Colors.red,
      onPressed: onTap,
      child: Icon(icon, size: 20, color: Colors.white),
    ),
  );
}

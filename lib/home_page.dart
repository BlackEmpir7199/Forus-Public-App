import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(MaterialApp(
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedChipIndex = 0;
  final List<String> chipLabels = ['Camps', 'Safe Places', 'Medical', 'Food Supplies'];
  final List<IconData> chipIcons = [Icons.campaign, Icons.shield, Icons.local_hospital, Icons.fastfood];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapSample(selectedChipIndex: selectedChipIndex),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: 16, right: 16, top: 30),
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search...',
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.search, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/profile_image.jpg'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int index = 0; index < chipLabels.length; index++)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          avatar: Icon(chipIcons[index], color: selectedChipIndex == index ? Colors.white : Colors.black),
                          label: Text(chipLabels[index]),
                          selected: selectedChipIndex == index,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedChipIndex = selected ? index : 0;
                            });
                            _zoomToLocation(index);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _zoomToLocation(int index) {
    final locations = [
      LatLng(13.0827, 80.2707), // Camps
      LatLng(13.0674, 80.2370), // Safe Places
      LatLng(13.0965, 80.2731), // Medical
      LatLng(13.0878, 80.2745), // Food Supplies
    ];

    final GoogleMapController controller = _mapSampleKey.currentState!.controller;
    final newCameraPosition = CameraPosition(
      target: locations[index],
      zoom: 18.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  final GlobalKey<MapSampleState> _mapSampleKey = GlobalKey();
}

class MapSample extends StatefulWidget {
  final int selectedChipIndex;

  const MapSample({Key? key, required this.selectedChipIndex}) : super(key: key);

  @override
  MapSampleState createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  GoogleMapController get controller => _controller.future as GoogleMapController;

  LocationData? currentLocation;
  BitmapDescriptor? userMarkerIcon;
  List<Marker> _markers = [];
  List<Circle> _circles = [];
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.0827, 80.2707),
    zoom: 15.0,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkerIcons();
    _generateRandomDisasterMarkers();
    _generateRandomNearbyMarkers();
  }

  Future<void> _loadMarkerIcons() async {
    userMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/profile_image.jpg',
    );
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    try {
      currentLocation = await location.getLocation();
      if (mounted) {
        setState(() {
          moveCameraToLocation(currentLocation!);
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

  void _generateRandomNearbyMarkers() {
    List<LatLng> disasterLocations = [
      LatLng(15.0827, 83.2707),  // Example disaster location 1
      LatLng(13.0674, 80.2370),  // Example disaster location 2
      LatLng(13.0965, 80.2731),  // Example disaster location 3
    ];

    List<IconData> campIcons = [
      Icons.campaign,         // Camps
      Icons.shield,           // Safe Places
      Icons.local_hospital,   // Medical
      Icons.fastfood,         // Food Supplies
    ];

    for (int i = 0; i < disasterLocations.length; i++) {
      LatLng disasterLocation = disasterLocations[i];

      // Generate random offsets for camp locations
      double latOffset = Random().nextDouble() * 0.02 - 0.01; // Example latitude offset (-0.01 to +0.01)
      double lngOffset = Random().nextDouble() * 0.02 - 0.01; // Example longitude offset (-0.01 to +0.01)

      // Generate camp locations near the disaster location
      for (int j = 0; j < campIcons.length; j++) {
        LatLng campLocation = LatLng(
          disasterLocation.latitude + latOffset,
          disasterLocation.longitude + lngOffset,
        );

        IconData icon = campIcons[j];
        _addCustomMarker(campLocation, icon, 'Location ${i}_${j}');
      }
    }
  }

  void _generateRandomDisasterMarkers() {
    List<LatLng> disasterLocations = [
      LatLng(15.0827, 83.2707),  // Example disaster location 1
      LatLng(13.0674, 80.2370),  // Example disaster location 2
      LatLng(13.0965, 80.2731),  // Example disaster location 3
    ];

    List<Color> disasterColors = [
      Colors.red,     // High damage
      Colors.orange,  // Medium damage
      Colors.green,   // Low damage
    ];

    for (int i = 0; i < disasterLocations.length; i++) {
      LatLng location = disasterLocations[i];
      Color color = disasterColors[i];

      _markers.add(Marker(
        markerId: MarkerId('disaster_marker_$i'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onTap: () {
          _showDisasterInfo(location, color, 'Disaster $i');
        },
      ));

      _circles.add(Circle(
        circleId: CircleId('disaster_circle_$i'),
        center: location,
        radius: 500,
        fillColor: color.withOpacity(0.3),
        strokeColor: color,
        strokeWidth: 2,
      ));
    }
  }

  Future<void> _addCustomMarker(LatLng position, IconData icon, String title) async {
    final Uint8List markerIcon = await createCustomMarkerIcon(icon, title);
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(title),
        position: position,
        icon: BitmapDescriptor.fromBytes(markerIcon),
        onTap: () {
          _showCampInfo(position, icon, title);
        },
      ));
    });
  }

  Future<Uint8List> createCustomMarkerIcon(IconData icon, String title) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double size = 100.0;

    final Paint paint = Paint()..isAntiAlias = true;
    final Radius radius = Radius.circular(size / 2);
    final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.clipRRect(rrect);

    // Draw background
    paint.color = Colors.lightBlue.withOpacity(0.8);
    canvas.drawRRect(rrect, paint);

    // Draw icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.6,
          fontFamily: icon.fontFamily,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    iconPainter.layout();
    iconPainter.paint(canvas, Offset(size * 0.2, size * 0.15));

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image markerImage = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showCampInfo(LatLng position, IconData icon, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            width: 150,
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Description of the location...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // Handle view more action
                  },
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDisasterInfo(LatLng position, Color color, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Container(
            width: 150,
            height: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Description of the disaster...',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // Handle view more action
                  },
                  child: Text(
                    'View More',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          markers: Set.from(_markers),
          circles: Set.from(_circles),
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),
        if (currentLocation != null && userMarkerIcon != null)
          Positioned(
            bottom: 50,
            right: 16,
            child: GestureDetector(
              onTap: moveToUserLocation,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.8),
                      spreadRadius: 2,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage('assets/profile_image.jpg'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void moveCameraToLocation(LocationData location) async {
    final GoogleMapController controller = await _controller.future;
    final newCameraPosition = CameraPosition(
      target: LatLng(location.latitude!, location.longitude!),
      zoom: 18.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }

  void moveToUserLocation() async {
    if (currentLocation != null) {
      final GoogleMapController controller = await _controller.future;
      final newCameraPosition = CameraPosition(
        target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
        zoom: 18.0,
      );
      controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
    }
  }

  void findNearbyLocations(int selectedChipIndex) async {
    List<LatLng> disasterLocations = [
      LatLng(15.0827, 83.2707),  // Example disaster location 1
      LatLng(13.0674, 80.2370),  // Example disaster location 2
      LatLng(13.0965, 80.2731),  // Example disaster location 3
    ];

    LatLng location;
    switch (selectedChipIndex) {
      case 0:
        location = disasterLocations[0];
        break;
      case 1:
        location = disasterLocations[1];
        break;
      case 2:
        location = disasterLocations[2];
        break;
      case 3:
        location = disasterLocations[0];
        break;
      default:
        location = disasterLocations[0];
        break;
    }

    final GoogleMapController controller = await _controller.future;
    final newCameraPosition = CameraPosition(
      target: location,
      zoom: 18.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }
}

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
                            MapSampleState().findNearbyLocations(selectedChipIndex);
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
}

class RoundedIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const RoundedIconButton({
    Key? key,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class MapSample extends StatefulWidget {
  final int selectedChipIndex;

  const MapSample({Key? key, required this.selectedChipIndex}) : super(key: key);

  @override
  MapSampleState createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LocationData? currentLocation;
  BitmapDescriptor? userMarkerIcon;
  List<Marker> _markers = [];
  List<Circle> _circles = [];
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.0827, 80.2707),
    zoom: 30.0,
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
    final Uint8List markerIcon = await getBytesFromAsset('assets/profile_image.jpg', 100);
    final Uint8List customMarker = await createCustomMarkerIcon(markerIcon);
    userMarkerIcon = BitmapDescriptor.fromBytes(customMarker);
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }

  Future<Uint8List> createCustomMarkerIcon(Uint8List imageBytes) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double size = 100.0;

    final Paint paint = Paint()..isAntiAlias = true;

    final Radius radius = Radius.circular(size / 2);
    final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.clipRRect(rrect);
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, paint);

    paint
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(rrect, paint);

    final Paint pinPaint = Paint()..color = Colors.blue.withOpacity(0.8);
    final Path pinPath = Path()
      ..moveTo(size / 2, size)
      ..lineTo((size / 2) - 10, size + 20)
      ..lineTo((size / 2) + 10, size + 20)
      ..close();
    canvas.drawPath(pinPath, pinPaint);

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image markerImage = await picture.toImage(size.toInt(), (size + 20).toInt());
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
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

      _markers.add(Marker(
        markerId: MarkerId('camp_marker_${i}_${j}'),
        position: campLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        onTap: () {
          _showCampInfo(campLocation, icon, 'Location ${i}_${j}');
        },
      ));
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
              onTap:moveToUserLocation,
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
    LatLng location;
    switch (selectedChipIndex) {
      case 0:
        location = LatLng(13.0827, 80.2707); // Chennai coordinates for 'Camps'
        break;
      case 1:
        location = LatLng(13.0674, 80.2370); // Chennai coordinates for 'Safe Places'
        break;
      case 2:
        location = LatLng(13.0965, 80.2731); // Chennai coordinates for 'Medical'
        break;
      case 3:
        location = LatLng(13.0878, 80.2745); // Chennai coordinates for 'Food Supplies'
        break;
      default:
        location = LatLng(13.0827, 80.2707); // Default to Chennai
        break;
    }
    moveCameraToLocation(currentLocation!);
    // final GoogleMapController controller = await _controller.future;
    // final newCameraPosition = CameraPosition(
    //   target: location,
    //   zoom: 14.0,
    // );
    // controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }
}

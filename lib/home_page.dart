import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

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
            child: MapSample(
              selectedChipIndex: selectedChipIndex,
            ),
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
                  children: List<Widget>.generate(
                    chipLabels.length,
                    (int index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          avatar: Icon(chipIcons[index], color: selectedChipIndex == index ? Colors.white : Colors.black),
                          label: Text(chipLabels[index]),
                          selected: selectedChipIndex == index,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedChipIndex = selected ? index : 0;
                            });
                          },
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
            ],
          ),
        ],
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
  BitmapDescriptor? pinLocationIcon;
  List<Marker> _markers = [];
  List<Circle> _circles = [];

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkerIcon();
    _generateRandomDisasterMarkers();
  }

  Future<void> _loadMarkerIcon() async {
    final Uint8List markerIcon = await getBytesFromAsset('assets/profile_image.jpg', 100);
    final Uint8List customMarker = await createCustomMarkerIcon(markerIcon);
    pinLocationIcon = BitmapDescriptor.fromBytes(customMarker);
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
      ..color = Colors.orange.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(rrect, paint);

    for (double radius = size / 2 + 5; radius <= size / 2 + 15; radius += 5) {
      paint
        ..color = Colors.orange.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(size / 2, size / 2), radius, paint);
    }

    final Paint pinPaint = Paint()..color = Colors.orange.withOpacity(0.8);
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

  void _generateRandomDisasterMarkers() {
    List<LatLng> disasterLocations = [
      LatLng(37.428, -122.085),
      LatLng(37.430, -122.083),
      LatLng(37.432, -122.087),
    ];

    List<Color> disasterColors = [Colors.red, Colors.orange, Colors.green];

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
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () {
              if (currentLocation != null) {
                moveCameraToLocation(currentLocation!);
              }
            },
            child: Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  void moveCameraToLocation(LocationData location) async {
    final GoogleMapController controller = await _controller.future;
    final newCameraPosition = CameraPosition(
      target: LatLng(location.latitude!, location.longitude!),
      zoom: 14.0,
    );
    controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition));
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                  backgroundImage: AssetImage('assets/profile_image.jpg'), // Replace with your profile image asset
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text("Map View"),
              Text("View Map")
            ],
          )
          ,
          Container(
            height: 220,
            child: MapSample(),
          ),
        ],
      ),
    );
  }
}

class MapSample extends StatefulWidget {
  const MapSample({Key? key}) : super(key: key);

  @override
  MapSampleState createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  LocationData? currentLocation;
  BitmapDescriptor? pinLocationIcon;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadMarkerIcon();
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
    final double size = 100.0; // Customize the size as needed

    final Paint paint = Paint()..isAntiAlias = true;

    // Draw the circular image
    final Radius radius = Radius.circular(size / 2);
    final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.clipRRect(rrect);
    final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), rect, paint);

    // Draw the border
    paint
      ..color = Colors.orange.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawRRect(rrect, paint);

    // Draw the concentric circles
    for (double radius = size / 2 + 5; radius <= size / 2 + 15; radius += 5) {
      paint
        ..color = Colors.orange.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(Offset(size / 2, size / 2), radius, paint);
    }

    // Draw the pin leg (inverted triangle)
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
        // Handle case when location services are still not enabled
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // Handle case when location permissions are denied
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
      // Handle any potential exceptions while fetching location
      print('Error fetching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: GoogleMap(
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        initialCameraPosition: _kGooglePlex,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: Set.from([
          if (currentLocation != null)
            Marker(
              markerId: MarkerId('marker_current_location'),
              position: LatLng(
                currentLocation!.latitude ?? 0.0,
                currentLocation!.longitude ?? 0.0,
              ),
              icon: pinLocationIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(
                title: 'Current Location',
                snippet: 'Your location',
              ),
            ),
        ]),
      ),
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

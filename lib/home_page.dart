import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
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

  final GlobalKey<MapSampleState> _mapSampleKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: MapSample(key: _mapSampleKey, selectedChipIndex: selectedChipIndex),
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
                    GestureDetector(
                      onTap: () {
                        final mapSampleState = _mapSampleKey.currentState;
                        if (mapSampleState != null) {
                          mapSampleState.zoomToUserLocation();
                        }
                      },
                      child: CircleAvatar(
                        radius: 20,
                        foregroundImage: AssetImage('assets/profile_image.jpg'),
                      ),
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
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                final mapSampleState = _mapSampleKey.currentState;
                if (mapSampleState != null) {
                  mapSampleState.zoomToUserLocation();
                }
              },
              child: Icon(Icons.my_location),
            ),
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
    _fetchDisasterData();
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
          _addUserMarker(currentLocation!);
        });
      }
    } catch (e) {
      print('Error fetching location: $e');
    }
  }

Future<void> _fetchDisasterData() async {
  try {
    final response = await http.get(Uri.parse('https://sachet.ndma.gov.in/cap_public_website/FetchAllAlertDetails'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      for (var disaster in data) {
        if (disaster['disseminated'] == 'true') { 
          LatLng location = LatLng(
            double.parse(disaster['centroid'].split(',')[1]),
            double.parse(disaster['centroid'].split(',')[0]),
          );
          String severity = disaster['severity'];
          String disasterType = disaster['disaster_type'];
          Color color = _getColorFromSeverityColor(disaster['severity_color']);

          _addDisasterMarker(location, disasterType, color, disaster);
        }
      }
    } else {
      print('Failed to load disaster data. Status code: ${response.statusCode}');
    }
  } catch (e) {
    print('Error fetching disaster data: $e');
  }
}

Color _getColorFromSeverityColor(String severityColor) {
  switch (severityColor.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'orange':
      return Colors.orange;
    case 'yellow':
      return Colors.yellow;
    case 'green':
      return Colors.green;
    default:
      return Colors.grey; 
  }
}

Future<void> _addDisasterMarker(LatLng position, String disasterType, Color color, Map<String, dynamic> disasterData) async {
  final Uint8List markerIcon = await createCustomMarkerIcon(Icons.warning, disasterType, color);
  setState(() {
    _markers.add(Marker(
      markerId: MarkerId(disasterData['identifier'].toString()),
      position: position,
      icon: BitmapDescriptor.fromBytes(markerIcon),
      onTap: () {
        _showDisasterInfo(position, disasterData);
      },
    ));

    _circles.add(Circle(
      circleId: CircleId(disasterData['identifier'].toString()),
      center: position,
      radius: 500,
      fillColor: color.withOpacity(0.3),
      strokeColor: color,
      strokeWidth: 2,
    ));
  });
}

  Future<void> _addUserMarker(LocationData location) async {
    final Uint8List markerIcon = await createCustomMarkerIcon(Icons.my_location, 'You', Colors.blue);
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('userLocation'),
        position: LatLng(location.latitude!, location.longitude!),
        icon: BitmapDescriptor.fromBytes(markerIcon),
      ));

      _circles.add(Circle(
        circleId: CircleId('userLocation'),
        center: LatLng(location.latitude!, location.longitude!),
        radius: 30,
        fillColor: Colors.blue.withOpacity(0.3),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ));
    });
  }

  Future<Uint8List> createCustomMarkerIcon(IconData icon, String title, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final double size = 100.0;

    final Paint paint = Paint()..isAntiAlias = true;
    final Radius radius = Radius.circular(size / 2);
    final Rect rect = Rect.fromLTWH(0.0, 0.0, size, size);
    final RRect rrect = RRect.fromRectAndRadius(rect, radius);
    canvas.clipRRect(rrect);

    // Draw background
    paint.color = color.withOpacity(0.8);
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

void _showDisasterInfo(LatLng position, Map<String, dynamic> disasterData) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Container(
          width: 350,
          height: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning, color: _getColorFromSeverityColor(disasterData['severity_color']), size: 40),
              SizedBox(height: 10),
              Text(
                disasterData['disaster_type'],
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Area: ${disasterData['area_description']}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 10),
              Text(
                'Severity Level: ${disasterData['severity_level']}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Warning Message: ${disasterData['warning_message']}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 6,
              ),
              SizedBox(height: 10),
              Text(
                'Start Time: ${disasterData['effective_start_time']}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'End Time: ${disasterData['effective_end_time']}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color:_getColorFromSeverityColor(disasterData['severity_color']),
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
void moveCameraToLocation(LocationData locationData) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationData.latitude!, locationData.longitude!),
          zoom: 15.0,
        ),
      ),
    );
  }

  void zoomToUserLocation() async {
    if (currentLocation != null) {
      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
            zoom: 18.0,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: _kGooglePlex,
      zoomControlsEnabled: false,
      markers: Set<Marker>.of(_markers),
      circles: Set<Circle>.of(_circles),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }
}

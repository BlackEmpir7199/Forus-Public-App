import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:location/location.dart';

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _temperature = '';
  String _description = '';
  String _location = '';
  String _icon = '';
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      LocationData locationData = await _determinePosition();
      final lat = locationData.latitude;
      final lon = locationData.longitude;
      final url = 'https://api.brightsky.dev/current_weather';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final weather = data['weather']?[0] ?? {};
        setState(() {
          _temperature = weather['temperature']?.toString() ?? 'N/A';
          _description = weather['condition'] ?? 'No description';
          _location = data['sources']?[0]['station_name'] ?? 'Unknown location';
          _icon = weather['icon'] ?? 'default_icon';
          _isLoading = false;
        });
      } else {
        _setError('Failed to load weather data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Error fetching weather data: $e');
    }
  }

  Future<LocationData> _determinePosition() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permission;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }
    }

    permission = await location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await location.requestPermission();
      if (permission != PermissionStatus.granted) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == PermissionStatus.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await location.getLocation();
  }

  void _setError(String message) {
    setState(() {
      _isLoading = false;
      _error = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black, Colors.grey[900]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : _error.isNotEmpty
                  ? _buildErrorText()
                  : _buildWeatherInfo(),
        ),
      ),
    );
  }

  Widget _buildErrorText() {
    return Text(
      _error,
      style: TextStyle(
        color: Colors.red,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildWeatherInfo() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _location,
          style: TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Image.network(
          'https://example.com/icons/$_icon.png', // Replace with correct icon URL
          width: 100,
          height: 100,
        ),
        SizedBox(height: 10),
        Text(
          '$_temperature°C',
          style: TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Text(
          _description.toUpperCase(),
          style: TextStyle(
            color: Colors.white70,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

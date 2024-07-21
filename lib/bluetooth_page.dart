import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(BluetoothPage());
}

class BluetoothPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothHomePage(),
    );
  }
}

class BluetoothHomePage extends StatefulWidget {
  @override
  _BluetoothHomePageState createState() => _BluetoothHomePageState();
}

class _BluetoothHomePageState extends State<BluetoothHomePage> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  final String username = "User1";
  final String userId = "12345";
  bool isConnecting = false;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  void requestPermissions() async {
    await FlutterBluePlus.turnOn();
    scanForDevices();
  }

  void scanForDevices() {
    FlutterBluePlus.startScan(timeout: Duration(seconds: 20));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Stop scanning once a device is found
        FlutterBluePlus.stopScan();
        connectToDevice(r.device);
        break;
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    setState(() {
      isConnecting = true;
    });
    await device.connect();
    setState(() {
      connectedDevice = device;
      isConnecting = false;
      isConnected = true;
    });
    showConnectionPopup();
  }

  void showConnectionPopup() {
    if (connectedDevice != null) {
      connectedDevice!.discoverServices().then((services) {
        for (BluetoothService service in services) {
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.properties.write) {
              characteristic.write(utf8.encode('$username,$userId'));
            }
          }
        }
      });
    }
  }

  void receiveData(BluetoothCharacteristic characteristic) {
    characteristic.value.listen((value) {
      String receivedData = utf8.decode(value);
      List<String> data = receivedData.split(',');
      String receivedUsername = data[0];
      String receivedUserId = data[1];
      showAlertDialog(receivedUsername, receivedUserId);
    });
  }

  void showAlertDialog(String receivedUsername, String receivedUserId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('New Connection'),
          content: Text('$receivedUsername with ID $receivedUserId has connected with you.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Connect'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isConnecting || isConnected ? null : scanForDevices,
              child: Text('Connect to Device'),
            ),
            SizedBox(height: 20),
            if (isConnecting) CircularProgressIndicator(),
            if (isConnected) Text('Connected to ${connectedDevice?.name}'),
          ],
        ),
      ),
    );
  }
}

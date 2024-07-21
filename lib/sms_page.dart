import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({Key? key}) : super(key: key);

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

class _ReadSmsScreenState extends State<ReadSmsScreen> {
  final Telephony telephony = Telephony.instance;
  String textReceived = "Waiting for message...";

  void startListening() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          setState(() {
            textReceived = message.body ?? "Error reading message body.";
          });
        },
        listenInBackground: false,
      );
    } else {
      setState(() {
        textReceived = "Permissions not granted.";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Read SMS Screen'),
      ),
      body: Center(
        child: Text(
          textReceived,
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

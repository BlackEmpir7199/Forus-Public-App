import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'database_helper.dart';
import 'dart:convert';

class ReadSmsScreen extends StatefulWidget {
  const ReadSmsScreen({Key? key}) : super(key: key);

  @override
  State<ReadSmsScreen> createState() => _ReadSmsScreenState();
}

class _ReadSmsScreenState extends State<ReadSmsScreen> {
  final Telephony telephony = Telephony.instance;
  final List<Map<String, dynamic>> _requests = [];
  final List<Map<String, dynamic>> _sentRequests = [];
  final String _targetNumber = '+919884752316';

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _startListening();
  }

  Future<void> _startListening() async {
    bool? permissionsGranted = await telephony.requestSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      telephony.listenIncomingSms(
        onNewMessage: (SmsMessage message) {
          if (message.address == _targetNumber) {
            _parseAndAddRequest(message.body ?? '', 'received');
          }
        },
        listenInBackground: false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('SMS permissions not granted.')),
      );
    }
  }
  
   Future<void> _clearAllRequests() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteAllRequests();
    _loadRequests();
  }

  Future<void> _clearAllReceivedRequests() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteAllReceivedRequests();
    _loadRequests();
  }

  Future<void> _clearAllSentRequests() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteAllSentRequests();
    _loadRequests();
  }

  Future<void> _parseAndAddRequest(String messageBody, String type) async {
    try {
      final data = jsonDecode(messageBody);
      final request = {
        'id': '${data['phone_no']}_${DateTime.now().millisecondsSinceEpoch}',
        'name': data['name'] ?? 'Unknown',
        'goods_required': data['goods_required'] ?? 'N/A',
        'quantity': data['quantity'] ?? 'N/A',
        'address': data['address'] ?? 'N/A',
        'phone_no': data['phone_no'] ?? 'N/A',
        'timestamp': DateTime.now().toIso8601String(),
        'type': type,
      };

      final dbHelper = DatabaseHelper();
      await dbHelper.insertRequest(request);
      _loadRequests();
    } catch (e) {
      print('Error parsing message body: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing message: $e')),
      );
    }
  }

  Future<void> _loadRequests() async {
    final dbHelper = DatabaseHelper();
    await dbHelper.deleteExpiredRequests();

    final requests = await dbHelper.getRequests();
    final now = DateTime.now();

    setState(() {
      _requests.clear();
      _sentRequests.clear();
      for (var item in requests) {
        final timestamp = DateTime.parse(item['timestamp']);
        if (item['type'] == 'received' && now.difference(timestamp).inHours < 24) {
          _requests.add(item);
        } else if (item['type'] == 'sent') {
          _sentRequests.add(item);
        }
      }
    });
  }

  void _sendRequest(Map<String, dynamic> request) {
    final message = jsonEncode(request);
    telephony.sendSms(
      to: _targetNumber,
      message: message,
    );
    _parseAndAddRequest(message, 'sent');
  }

  Future<void> _showSendRequestDialog() async {
    final nameController = TextEditingController();
    final goodsRequiredController = TextEditingController();
    final quantityController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Send Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: InputDecoration(labelText: 'Name')),
              TextField(controller: goodsRequiredController, decoration: InputDecoration(labelText: 'Goods Required')),
              TextField(controller: quantityController, decoration: InputDecoration(labelText: 'Quantity')),
              TextField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone Number')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final request = {
                  'name': nameController.text,
                  'goods_required': goodsRequiredController.text,
                  'quantity': quantityController.text,
                  'address': addressController.text,
                  'phone_no': phoneController.text,
                  'type': 'sent',
                };
                _sendRequest(request);
                Navigator.of(context).pop();
              },
              child: Text('Send'),
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
        title: const Text('People Requests'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _showSendRequestDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('People Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _requests.isEmpty
                ? Center(child: Text('No requests received.'))
                : ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final request = _requests[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(request['name'], style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            '${request['goods_required']} (${request['quantity']})\nAddress: ${request['address']}\nPhone: ${request['phone_no']}',
                            style: TextStyle(color: Colors.black),
                          ),
                          isThreeLine: true,
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                            onPressed: () {
                              // Implement donate action
                            },
                            child: Text('Donate', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Your Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _sentRequests.isEmpty
                ? Center(child: Text('No requests sent.'))
                : ListView.builder(
                    itemCount: _sentRequests.length,
                    itemBuilder: (context, index) {
                      final request = _sentRequests[index];
                      return Card(
                        margin: EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(request['name'], style: TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text(
                            '${request['goods_required']} (${request['quantity']})\nAddress: ${request['address']}\nPhone: ${request['phone_no']}',
                            style: TextStyle(color: Colors.black),
                          ),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () {
                                  final dbHelper = DatabaseHelper();
                                  dbHelper.deleteRequest(request['id']);
                                  _loadRequests();
                                },
                                child: Text('Satisfied', style: TextStyle(color: Colors.white)),
                              ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  final dbHelper = DatabaseHelper();
                                  dbHelper.deleteRequest(request['id']);
                                  _loadRequests();
                                },
                                child: Text('Delete', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _clearAllReceivedRequests,
                  child: Text('Clear All Received'),
                ),
                ElevatedButton(
                  onPressed: _clearAllSentRequests,
                  child: Text('Clear All Sent'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

class DonationPage extends StatefulWidget {
  @override
  _DonationPageState createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  List<Map<String, dynamic>> donationRequests = [
    {
      'id': '1',
      'name': 'Request #1',
      'cause': 'Cause #1',
      'address': '123 Street, City',
      'description': 'Description of request #1',
      'image': 'https://via.placeholder.com/150',
      'requestedItems': [
        {'item': 'Apple', 'requestedQty': 50, 'donatedQty': 0},
        {'item': 'Banana', 'requestedQty': 30, 'donatedQty': 0}
      ]
    },
    {
      'id': '2',
      'name': 'Request #2',
      'cause': 'Cause #2',
      'address': '456 Avenue, City',
      'description': 'Description of request #2',
      'image': 'https://via.placeholder.com/150',
      'requestedItems': [
        {'item': 'Rice', 'requestedQty': 100, 'donatedQty': 0},
        {'item': 'Beans', 'requestedQty': 75, 'donatedQty': 0}
      ]
    },
    {
      'id': '3',
      'name': 'Request #3',
      'cause': 'Cause #3',
      'address': '789 Boulevard, City',
      'description': 'Description of request #3',
      'image': 'https://via.placeholder.com/150',
      'requestedItems': [
        {'item': 'Milk', 'requestedQty': 20, 'donatedQty': 0},
        {'item': 'Bread', 'requestedQty': 15, 'donatedQty': 0}
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donation', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donate',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDonationCategory('Food', Icons.fastfood),
                  _buildDonationCategory('Clothing', Icons.checkroom),
                  _buildDonationCategory('Snacks', Icons.local_cafe),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: MaterialButton(
                  color: Colors.black,
                  onPressed: () => {},
                  minWidth: 200,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.money, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Donate Money', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Inventory Requests',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.black),
              ),
              SizedBox(height: 20),
              _buildInventoryRequestsList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDonationCategory(String title, IconData icon) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.black,
          radius: 28,
          child: Icon(
            icon,
            size: 28,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        Text(title),
      ],
    );
  }

  Widget _buildInventoryRequestsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: donationRequests.length,
      itemBuilder: (context, index) {
        final request = donationRequests[index];
        return _buildInventoryRequest(request);
      },
    );
  }

  Widget _buildInventoryRequest(Map<String, dynamic> request) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  request['image'],
                  height: 80,
                  width: 80,
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request['name'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 5),
                  Text(request['cause']),
                  SizedBox(height: 5),
                  Text(request['address']),
                ],
              ),
            ],
          ),
          SizedBox(height: 15),
          Text(request['description']),
          SizedBox(height: 10),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: request['requestedItems'].length,
            itemBuilder: (context, itemIndex) {
              final item = request['requestedItems'][itemIndex];
              return _buildRequestedItemTile(item);
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              onPressed: () {
                _showDonationPopup(context, request);
              },
              child: Text('Donate', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestedItemTile(Map<String, dynamic> item) {
    return ListTile(
      title: Text(item['item']),
      subtitle: Text('Requested: ${item['requestedQty']}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () {
              setState(() {
                if (item['donatedQty'] > 0) item['donatedQty']--;
              });
            },
          ),
          Text('${item['donatedQty']}'),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              setState(() {
                item['donatedQty']++;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showDonationPopup(BuildContext context, Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Donation to ${request['name']}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                ...request['requestedItems'].map((item) {
                  return ListTile(
                    title: Text(item['item']),
                    subtitle: Text('Donated: ${item['donatedQty']} / Requested: ${item['requestedQty']}'),
                  );
                }).toList(),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: () {
                    // Logic to handle goods donation
                    Navigator.of(context).pop();
                  },
                  child: Text('Confirm Donation', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showMoneyDonationPopup(BuildContext context) {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Donate Money'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Enter amount'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: Text('Donate'),
              onPressed: () {
                // Logic to handle money donation
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

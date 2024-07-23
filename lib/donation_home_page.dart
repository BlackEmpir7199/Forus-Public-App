import 'package:flutter/material.dart';
import 'package:foruspublic/inventory_donation_page.dart';
import 'package:foruspublic/people_donation_page.dart';

class DonationHomePage extends StatefulWidget {
  const DonationHomePage({super.key});

  @override
  State<DonationHomePage> createState() => _DonationHomePageState();
}

class _DonationHomePageState extends State<DonationHomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.black,
        toolbarHeight: 40,
        bottom: TabBar(
         labelColor: Colors.lightBlueAccent,
         
         indicatorColor: Colors.lightBlueAccent,
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
            Tab(icon: Icon(Icons.people), text: 'People'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DonationPage(),
          ReadSmsScreen()
        ],
      ),
    );
    }
  }
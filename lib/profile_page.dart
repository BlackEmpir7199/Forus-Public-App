import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';
import 'signup_screen.dart';
import 'user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: FutureBuilder<bool>(
        future: _checkIfLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.data == true) {
              return ProfilePage();
            } else {
              return SignUpScreen();
            }
          }
        },
      ),
    );
  }

  Future<bool> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
    });
  }

  Future<void> _deleteUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username != null) {
      await _databaseHelper.deleteUser(username);
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('username');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_image.jpg'),
            ),
            SizedBox(height: 20),
            Text(
              _username ?? 'Loading...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            ProfileMenuItem(
              icon: Icons.person,
              text: 'Edit Profile',
              onTap: () {
                // Navigate to edit profile screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.lock,
              text: 'Change Password',
              onTap: () {
                // Navigate to change password screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.notifications,
              text: 'Notification Preferences',
              onTap: () {
                // Navigate to notification preferences screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.security,
              text: 'Privacy Settings',
              onTap: () {
                // Navigate to privacy settings screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.help,
              text: 'Help & Support',
              onTap: () {
                // Navigate to help & support screen
              },
            ),
            ProfileMenuItem(
              icon: Icons.delete,
              text: 'Delete User',
              onTap: () async {
                await _deleteUser(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        text,
        style: TextStyle(color: Colors.black),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.black),
      onTap: onTap,
    );
  }
}

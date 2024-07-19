import 'package:flutter/material.dart';

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
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings',style: TextStyle(color:Colors.white),),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            SizedBox(height: 20),
            Text(
              'John Doe',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'johndoe@example.com',
              style: TextStyle(fontSize: 16, color: Colors.amber[900]),
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
              icon: Icons.logout,
              text: 'Logout',
              onTap: () {
                // Handle logout
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

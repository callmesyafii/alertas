import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'editprofile.dart';

class ProfileSettings extends StatefulWidget {
  final String ipAddr = '192.168.1.24';
  final String username;

  const ProfileSettings({super.key, required this.username});

  @override
  _ProfileSettingsState createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  String username = '';
  String email = '';
  String password = '';
  String kodeAlat = '';
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _kodeAlatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString('email') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://${widget.ipAddr}/alertasAndro/profile.php'),
        body: {
          'email': email,
        },
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['message'] == null) {
          setState(() {
            _usernameController.text = data['username'];
            _emailController.text = email;
            _passwordController.text = data['sandi'];
            _kodeAlatController.text = data['kode'];
          });
        } else {
          setState(() {
          });
        }
      } else {
        setState(() {
        });
      }
    } catch (e) {
      setState(() {
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: FutureBuilder<void>(
          future: null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            return Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x171A1F12),
                    blurRadius: 1,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Color(0x171A1F1F),
                    blurRadius: 2,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Profile settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField('Username', _usernameController, readOnly: true),
                  _buildTextField('Email', _emailController, readOnly: true),
                  _buildTextField('Password', _passwordController, obscureText: true, readOnly: true),
                  _buildTextField('Kode Alat', _kodeAlatController, readOnly: true),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfile(username: widget.username)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF024D94),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            decoration: InputDecoration(
              hintText: 'Masukkan $label',
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserData() async {
    final response = await http.post(
      Uri.parse('http://$widget.ipAddr/alertasAndro/updateProfile.php'),
      body: {
        'username': widget.username,
        'email': email,
        'password': password,
        'kodeAlat': kodeAlat,
      },
    );

    if (response.statusCode == 200) {
      jsonDecode(response.body);
    } else {
    }
  }
}

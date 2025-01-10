import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Color buttonColor = const Color(0xff024d94ff);
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController kodeAlatController = TextEditingController();
  String ipAddr = '192.168.1.24'; 

  Future<void> _login() async {
    String email = emailController.text;
    String password = passwordController.text;
    String kodeAlat = kodeAlatController.text;

    final response = await http.post(
      Uri.parse('http://$ipAddr/alertasAndro/login.php'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'email': email,
        'password': password,
        'kodeAlat': kodeAlat,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email); 
        await prefs.setString('sandi', password); 
       
        Navigator.pushReplacementNamed(context, '/dashboard'); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat login')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome 👋',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 32,
                      height: 1.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 348,
                    height: 79,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter email',
                            filled: true,
                            fillColor: const Color(0xfff3f4f6ff),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 348,
                    height: 79,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Password', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            hintText: 'Enter password',
                            filled: true,
                            fillColor: const Color(0xfff3f4f6ff),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            suffixIcon: const Icon(Icons.visibility_off),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 348,
                    height: 79,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Kode Alat', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: kodeAlatController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan Kode Alat',
                            filled: true,
                            fillColor: const Color(0xfff3f4f6ff),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF024D94),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      minimumSize: const Size(348, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                      alignment: Alignment.center,
                    ),
                    onHover: (isHovered) {
                      setState(() {
                        buttonColor = isHovered ? const Color(0xff023667ff) : const Color(0xff024d94ff);
                      });
                    },
                    child: const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      
                      Navigator.pushNamed(context, '/register'); 
                    },
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 26 / 16, 
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF171A1F), 
                            ),
                          ),
                          TextSpan(
                            text: "Sign up",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              height: 26 / 16, 
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF636AE8), 
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'welcome.dart'; 
import 'register.dart';
import 'login.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WelcomeScreen(), 
      routes: {
        '/register': (context) => const RegisterScreen(), 
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const Dashboard(),
      },
    );
  }
}

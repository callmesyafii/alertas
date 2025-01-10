import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String ipAddr = '192.168.1.24';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String ppmValue = 'Loading...';
  Timer? timer;
  String detectionHistoryCount = '0';
  String connectionStatus = 'Not Connected';
  String username = '';
  String email = '';
  String password = '';
  List<String> sensorValues = [];
  String latestPrediction = 'No prediction available';

  @override
  void initState() {
    super.initState();
    _getUserData();
    fetchPPMValue();
    checkConnectionStatus();
    fetchPredictions();
    fetchLatestPrediction();

    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) async {
      await fetchPPMValue();
      await fetchDetectionHistoryCount();
      await checkConnectionStatus();
      await fetchPredictions();
      await fetchLatestPrediction();
      setState(() {});
    });
  }

  Future<void> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'User';
      email = prefs.getString('email') ?? '';
      password = prefs.getString('password') ?? '';
    });

    String kodeAlat = username; 
    await _storeKodeAlat(kodeAlat);
  }

  Future<void> _storeKodeAlat(String kodeAlat) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('kode_alat', kodeAlat);
  }

  Future<void> fetchPPMValue() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddr/alertasAndro/android/kirimdata.php?action=getPPM'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['nilaiLpg'] != null) {
          setState(() {
            ppmValue = data['nilaiLpg'].toString();
          });
        } else {
          setState(() {
            ppmValue = 'No data available';
          });
        }
      } else {
        setState(() {
          ppmValue = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        ppmValue = 'Error';
      });
    }

    await fetchDetectionHistoryCount();
  }

  Future<void> fetchDetectionHistoryCount() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddr/alertasAndro/get_detection_history.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          detectionHistoryCount = data['count'].toString();
        });
      } else {
        setState(() {
          detectionHistoryCount = 'Error';
        });
      }
    } catch (e) {
      setState(() {
        detectionHistoryCount = 'Error';
      });
    }
  }

  Future<void> checkConnectionStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://$ipAddr/alertasAndro/android/kirimdata.php?action=checkConnection'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          connectionStatus = data['status'];
        });
      } else {
        setState(() {
          connectionStatus = 'Not Connected';
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = 'Not Connected';
      });
    }
  }

  String _getAlertStatus(double ppm) {
    if (ppm < 2.0) {
      return 'Safe';
    } else if (ppm < 3.0) {
      return 'Warning';
    } else {
      return 'Critical Alert';
    }
  }

  String getAlertStatus() {
    try {
      double ppm = double.parse(ppmValue);
      return _getAlertStatus(ppm);
    } catch (e) {
      return 'Invalid PPM Value';
    }
  }

  Future<void> fetchPredictions() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddr/alertasAndro/predictions.php'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double maxPredictionValue = data['max_value'] != null ? double.parse(data['max_value'].toString()) : 0.0;

        String finalStatus;
        if (maxPredictionValue < 2) {
          finalStatus = 'Tidak ada ancaman';
        } else if (maxPredictionValue < 3) {
          finalStatus = 'Waspada';
        } else {
          finalStatus = 'Risiko Kebocoran Tinggi';
        }

        setState(() {
          if (maxPredictionValue > 0) {
            sensorValues.add(maxPredictionValue.toString());
          }
        });
      } else {
        // Handle error
      }
    } catch (e) {
      // Handle exception
    }
  }

  String _getPredictionStatus(double predictionValue) {
    if (predictionValue < 2) {
      return 'Tidak ada ancaman';
    } else if (predictionValue >= 2 && predictionValue < 3) {
      return 'Waspada';
    } else {
      return 'Risiko Kebocoran Tinggi';
    }
  }

  Future<void> fetchLatestPrediction() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddr/alertasAndro/predictions.php'));
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          latestPrediction = data['latest_prediction']?.toString() ?? 'No prediction available';
        });
      }
    } catch (e) {
      setState(() {
        latestPrediction = 'Error fetching prediction';
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    child: const Text(
                      'Overview',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 32,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfileSettings(username: username)),
                      );
                    },
                    child: Text('Hi $username', style: const TextStyle(fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                width: 541,
                height: 258,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Gas Safety Score',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 18,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171A1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ppmValue,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          height: 1.57,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF171A1F),
                        ),
                        children: [
                          const TextSpan(text: 'Berdasarkan analisis, skor keamanan gas kamu adalah '),
                          TextSpan(
                            text: getAlertStatus(),
                            style: TextStyle(
                              color: getAlertStatus() == 'Safe'
                                  ? Colors.green
                                  : getAlertStatus() == 'Warning'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.w900
                            ),
                          ),
                          const TextSpan(text: '. Tetap pantau aplikasi untuk mengetahui nilai PPM secara real-time.'),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Tell me more'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // New Prediction Card
              SizedBox(
                width: double.infinity,
                child: Card(
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Prediksi Status PPM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sensorValues.isNotEmpty
                              ? _getPredictionStatus(double.parse(sensorValues.last))
                              : 'Tidak ada prediksi terbaru',
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Highlights',
                    style: TextStyle(
                      fontFamily: 'Archivo',
                      fontSize: 20,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      final response = await http.post(Uri.parse('http://$ipAddr/alertasAndro/reset_data.php'));
                      if (response.statusCode == 200) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data berhasil direset')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mereset data')));
                      }
                    },
                    child: const Text('Reset Data'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildHighlightCard('PPM', ppmValue, 'updated just now', Colors.purple),
                  _buildHighlightCard('Detection History', detectionHistoryCount, 'In the past 30 minutes', Colors.orange),
                  _buildHighlightCard('Safety Score', getAlertStatus(), 'updated a day ago', Colors.blue),
                  _buildHighlightCard('Connection Status', connectionStatus, 'updated just now', Colors.green),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCard(String title, String value, String updateTime, Color color) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Archivo',
                fontWeight: FontWeight.w500,
                height: 22 / 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(updateTime, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

const char* ssid = "Annisa Stay 2";
const char* password = "17081945";
const char* IPAddr = "192.168.1.24";

WiFiClient NodeMCU;

// OLED Configuration
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
#define SCREEN_ADDRESS 0x3C
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Pin Configuration
#define MQ_SENSOR A0
#define BUZZ 12

// Sensor Calibration Parameters
#define RL 10    // Load resistance in kOhms
#define Ro 2.7   // Sensor resistance in clean air

// LPG Calibration
#define alpg -0.44171
#define blpg 1.21962

float VRL, Rs, ratio, lpg;
bool alarmActive = false;
bool wifiConnected = false;

void setup() {
  Serial.begin(115200);
  delay(100);

  // Pin configuration
  pinMode(BUZZ, OUTPUT);
  digitalWrite(BUZZ, LOW);

  // Initialize OLED display
  if (!display.begin(SSD1306_SWITCHCAPVCC, SCREEN_ADDRESS)) {
    Serial.println(F("SSD1306 allocation failed"));
    while (1);
  }

  // Welcome message on OLED
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println(" IoT LPG ");
  display.println(" Detector ");
  display.display();
  delay(1000);

  // Start WiFi connection
  connectToWiFi();
}

void loop() {
  readSensorData();
  displayData();
  handleAlarm();

  checkWiFiStatus(); // Cek status WiFi secara periodik

  if (wifiConnected) {
    sendDataToServer();
    getPPMValue(); // Ambil nilai PPM dari server jika terhubung
  } else {
    Serial.println("WiFi tidak terhubung, hanya mode offline.");
  }

  delay(1000);   // Delay 1 detik
}

void connectToWiFi() {
  WiFi.begin(ssid, password);
  Serial.print("Menghubungkan ke WiFi");
  int attempt = 0;
  while (WiFi.status() != WL_CONNECTED && attempt < 20) { // Maks 20 percobaan
    delay(500);
    Serial.print(".");
    attempt++;
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\nWiFi Terhubung!");
    wifiConnected = true;
  } else {
    Serial.println("\nGagal terhubung ke WiFi.");
    wifiConnected = false;
  }
}

void checkWiFiStatus() {
  if (WiFi.status() != WL_CONNECTED) {
    wifiConnected = false;
    connectToWiFi();
  } else {
    wifiConnected = true;
  }
}

void readSensorData() {
  int sensorValue = analogRead(MQ_SENSOR);
  VRL = sensorValue * (3.3 / 1023.0); // Konversi tegangan
  Rs = ((3.3 * RL) / VRL) - RL;       // Resistansi sensor
  ratio = Rs / Ro;                    // Rasio sensor
  lpg = pow(10, (log10(ratio) - blpg) / alpg);
  Serial.print("LPG Level: ");
  Serial.print(lpg);
  Serial.println(" PPM");
}

void displayData() {
  display.clearDisplay();
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.println("LPG Level:");
  display.print("LPG: ");
  display.print(lpg);
  display.println(" PPM");
  display.display();
}

void handleAlarm() {
  if (lpg > 3) {
    Serial.println("ALERT: High LPG Levels Detected!");
    if (!alarmActive) {
      alarmActive = true;
      digitalWrite(BUZZ, HIGH);
    }
  } else if (alarmActive) {
    alarmActive = false;
    digitalWrite(BUZZ, LOW);
  }
}

void sendDataToServer() {
  HTTPClient http;

  String kodeAlat = "asdasd"; // Ganti dengan kode alat yang sesuai
  String lpgUrl = "http://" + String(IPAddr) + "/alertasAndro/android/kirimdata.php?nilaiLpg=" + String(lpg, 2) + "&kode_alat=" + kodeAlat;
  
  http.setTimeout(10000); // 10 detik
  http.begin(NodeMCU, lpgUrl); // Gunakan NodeMCU sebagai client
  
  int httpResponseCode = http.GET();

  if (httpResponseCode > 0) {
    Serial.print("Server Response Code: ");
    Serial.println(httpResponseCode);
  } else {
    Serial.print("Error Sending Data: ");
    Serial.println(http.errorToString(httpResponseCode).c_str());
  }
  http.end();
}

void getPPMValue() {
  HTTPClient http;

  String getPPMUrl = "http://" + String(IPAddr) + "/alertasAndro/android/kirimdata.php?action=getPPM";
  http.begin(NodeMCU, getPPMUrl); // Gunakan NodeMCU sebagai client
  
  int httpResponseCode = http.GET();

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.print("Raw Response: ");
    Serial.println(response); // Debug respons mentah server

    DynamicJsonDocument doc(1024);
    DeserializationError error = deserializeJson(doc, response);

    if (!error) {
      if (doc.containsKey("nilaiLpg") && !doc["nilaiLpg"].isNull()) {
        float ppmValue = doc["nilaiLpg"];
        Serial.print("PPM Value from Server: ");
        Serial.println(ppmValue);
      } else {
        Serial.println("PPM Value is null or not found in the response.");
      }
    } else {
      Serial.print("JSON Deserialization Error: ");
      Serial.println(error.c_str());
    }
  } else {
    Serial.print("Error Getting Data: ");
    Serial.println(http.errorToString(httpResponseCode).c_str());
  }

  http.end();
}

void checkConnectionStatus() {
  HTTPClient http;
  WiFiClient client;

  String checkConnectionUrl = "http://" + String(IPAddr) + "/alertasAndro/android/kirimdata.php?action=checkConnection";
  http.begin(client, checkConnectionUrl);
  
  int httpResponseCode = http.GET();

  if (httpResponseCode > 0) {
    Serial.println("Connected");
  } else {
    Serial.println("Not Connected");
  }

  http.end();
}
#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <BluetoothSerial.h>
#include <EEPROM.h>

/* 1. Define the API Key */
#define API_KEY "API_KEY"

/* 2. Define the RTDB URL */
#define DATABASE_URL "URL" //<databaseName>.firebaseio.com or <databaseName>.<region>.firebasedatabase.app

/* 3. Define the user Email and password that alreadey registerd or added in your project */
#define USER_EMAIL "USER_EMAIL"
#define USER_PASSWORD "USER_PASSWORD"

#define EEPROM_SIZE 512

BluetoothSerial SerialBT;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

const int led_gpio = 2;
char ssid[64] = "";
char password[64] = "";
bool led_state;
bool conf = false;

void setup() {
  Serial.begin(115200);
  SerialBT.begin("ESP32");
  EEPROM.begin(EEPROM_SIZE);
  pinMode(led_gpio, OUTPUT);
  if(!conf){
    resetEEPROM();
  }
  if (!readCredentialsFromEEPROM()) {
    Serial.println("Credentials not found in EEPROM. Entering setup mode.");
    setupMode();
  } else {
    Serial.println("Credentials found in EEPROM. Connecting to WiFi.");
    connectToWiFi();
  }
  Serial.printf("Firebase Client v%s\n\n", FIREBASE_CLIENT_VERSION);

  config.api_key = API_KEY;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;
  config.database_url = DATABASE_URL;
  config.token_status_callback = tokenStatusCallback;
  
  Firebase.reconnectWiFi(true);
  fbdo.setBSSLBufferSize(4096, 1024);
  fbdo.setResponseSize(2048);

  Firebase.begin(&config, &auth);
}

void loop() {
  if (Firebase.ready()) {
    if (Firebase.RTDB.getBool(&fbdo,"/LEDState/state")) {
      led_state = fbdo.to<bool>();
      Serial.print("Led is: ");
      Serial.println(led_state);
      digitalWrite(led_gpio, (led_state) ? HIGH : LOW);
    } else {
      Serial.println(fbdo.errorReason().c_str());
      Serial.println("Failed to get LED state from Firebase. Retrying...");
    }
  }
  delay(1000);
}

bool readCredentialsFromEEPROM() {
  EEPROM.get(0, ssid);
  EEPROM.get(64, password);
  return (strlen(ssid) > 0 && strlen(password) > 0);
}

void writeCredentialsToEEPROM() {
  EEPROM.put(0, ssid);
  EEPROM.put(64, password);
  EEPROM.commit();
}

void connectToWiFi() {
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");
}

void setupMode() {
  Serial.println("Entering setup mode for WiFi configuration");

  while (!SerialBT.available()) {
    // Wait for Bluetooth commands
    delay(1000);
  }

  Serial.println("Bluetooth command received");

  // Read WiFi credentials from Bluetooth
  String command = SerialBT.readStringUntil('\n');
  command.trim();  // Remove leading and trailing whitespaces, including '\r'

  int separatorIndex = command.indexOf(':');

  if (separatorIndex != -1) {
    strcpy(ssid, command.substring(0, separatorIndex).c_str());
    strcpy(password, command.substring(separatorIndex + 1).c_str());
    Serial.println("Received WiFi credentials from Bluetooth");
    SerialBT.println("SSID: " + String(ssid));
    SerialBT.println("Password: " + String(password));
    Serial.println("SSID: " + String(ssid));
    Serial.println("Password: " + String(password));
    // Save credentials to EEPROM
    writeCredentialsToEEPROM();

    // Connect to WiFi
    connectToWiFi();
  }
}

void resetEEPROM() {
  Serial.println("Resetting EEPROM...");
  for (int i = 0; i < EEPROM_SIZE; ++i) {
    EEPROM.write(i, 0);
  }
  EEPROM.commit();
}

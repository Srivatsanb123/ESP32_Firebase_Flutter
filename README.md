# ESP32 Bluetooth and Firebase Integration

## Overview
This project demonstrates the integration of an ESP32 (NodeMCU) with Bluetooth and Firebase to remotely control an LED and send WiFi credentials. The ESP32 is programmed using the Arduino framework, and the Flutter framework is used for the mobile app.

## Features
- **Bluetooth Connectivity:** Scan and connect to nearby Bluetooth devices.
- **Firebase Integration:** Connect to Firebase Realtime Database to control the LED state remotely.
- **WiFi Configuration:** Send WiFi credentials to the ESP32 via Bluetooth.

## Hardware Setup
1. Connect an LED to GPIO pin 2 on the ESP32.
2. Flash the provided ESP32 code to the board.

## Software Setup
### ESP32 Code
1. Replace placeholders in the ESP32 code (`esp32_code.ino`) with your Firebase and WiFi credentials.
2. Upload the code to your ESP32 board.

### Flutter Code
1. Update Firebase configurations in `main.dart` with your Firebase project details.
2. Install required dependencies using `pub get`.
3. Run the Flutter app on your device.

## Usage
1. Launch the Flutter app on your mobile device.
2. Click "Start Scan" to discover nearby Bluetooth devices.
3. Select your ESP32 device from the list to establish a Bluetooth connection.
4. Enter WiFi details in the app and click "Send WiFi Credentials" to update ESP32.
5. Toggle the LED state using "Toggle LED On" and "Toggle LED Off" buttons.

## Dependencies
- [Firebase Database](https://pub.dev/packages/firebase_database)
- [Flutter Bluetooth Serial](https://pub.dev/packages/flutter_bluetooth_seria_changed)
- [Permission Handler](https://pub.dev/packages/permission_handler)

## Contributing
Contributions are welcome! If you find any issues or have improvements, feel free to open an issue or submit a pull request.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- [Firebase](https://firebase.google.com/)
- [ESP32 Arduino Core](https://github.com/espressif/arduino-esp32)
- [Flutter](https://flutter.dev/)
- [Flutter Bluetooth Serial](https://github.com/edufolly/flutter_bluetooth_serial)

## Author
[Srivatsan](https://github.com/Srivatsanb123)</s> </s> </s> </s> </s>
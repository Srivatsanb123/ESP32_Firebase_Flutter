// ignore_for_file: library_private_types_in_public_api, avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_seria_changed/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:espled/firebase_options.dart';
import 'package:open_settings/open_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BluetoothScanPage(),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({Key? key}) : super(key: key);

  @override
  _BluetoothScanPageState createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  final List<BluetoothDiscoveryResult> _devicesList = [];
  BluetoothConnection? _bluetoothConnection;
  late final DatabaseReference fireRef;

  TextEditingController _ssidController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  DatabaseReference LedRef = FirebaseDatabase.instance.ref("LEDState");
  @override
  void initState() {
    super.initState();
  }

  void _toggleLedOn() {
    LedRef.child("state").set(1);
  }

  void _toggleLedOff() {
    LedRef.child("state").set(0);
  }

  Future<void> _checkBluetoothStatus() async {
    bool isEnabled = (await FlutterBluetoothSerial.instance.isEnabled) ?? false;
    if (!isEnabled) {
      _askUserToEnableBluetooth();
    } else {
      _startDiscovery();
    }
  }

  Future<void> _askUserToEnableBluetooth() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bluetooth is turned off'),
          content:
              const Text('Please turn on Bluetooth and try again to continue.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                OpenSettings.openBluetoothSetting();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> requestBluetoothScanPermission() async {
    var status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      PermissionStatus result = await Permission.bluetoothScan.request();
      if (result.isGranted) {
        _startDiscovery();
      } else {
        _showNotGrantedAlert();
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    } else {
      _checkBluetoothStatus();
    }
  }

  void _startDiscovery() async {
    setState(() {
      _devicesList.clear();
    });

    await FlutterBluetoothSerial.instance.cancelDiscovery();

    FlutterBluetoothSerial.instance.startDiscovery().listen((device) {
      setState(() {
        _devicesList.add(device);
      });
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      _disconnect();

      final BluetoothConnection connection =
          await BluetoothConnection.toAddress(device.address);

      print('Connected to ${device.name}');

      setState(() {
        _bluetoothConnection = connection;
      });
    } catch (error) {
      print('Error connecting to ${device.name}: $error');
    }
  }

  void _sendData(String data) {
    try {
      if (_bluetoothConnection != null) {
        _bluetoothConnection!.output.add(Uint8List.fromList(data.codeUnits));
        _bluetoothConnection!.output.allSent.then((_) {
          print('Data sent: $data');
        });
      } else {
        _showNotConnectedAlert();
      }
    } catch (error) {
      if (error is StateError) {
        _showNotPairedAlert();
      } else {
        print('Error sending data: $error');
      }
    }
  }

  void _showNotConnectedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Not Connected'),
          content: const Text(
              'Please connect to the device before sending WIFI credentials.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestBluetoothScanPermission();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotGrantedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: const Text(
              'Bluetooth permission not granted please grant access to continue.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestBluetoothScanPermission();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showNotPairedAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Device Not Paired'),
          content: const Text(
              'Please pair with a Bluetooth device before sending data.'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestBluetoothScanPermission();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _disconnect() {
    if (_bluetoothConnection != null) {
      _bluetoothConnection!.dispose();
      _bluetoothConnection = null;
      print('Disconnected');
    }
  }

  @override
  void dispose() {
    _disconnect();
    FirebaseDatabase.instance.goOffline(); // Close Firebase connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await requestBluetoothScanPermission();
                await connectToFirebase();
              },
              child: const Text('Start Scan'),
            ),
            const SizedBox(height: 16),
            const Text('Discovered Devices:'),
            Expanded(
              child: ListView.builder(
                itemCount: _devicesList.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_devicesList[index].device.name ?? 'Unknown'),
                    subtitle: Text(_devicesList[index].device.address),
                    trailing: _devicesList[index].device.isBonded
                        ? const Icon(Icons.bluetooth_connected,
                            color: Colors.green)
                        : const Icon(Icons.bluetooth, color: Colors.grey),
                    onTap: () {
                      _connectToDevice(_devicesList[index].device);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text("Enter the WIFI Details:"),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'Enter Wifi Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Enter Password'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                String ssid = _ssidController.text;
                String password = _passwordController.text;
                _sendData('$ssid:$password');
              },
              child: const Text('Send WiFi Credentials'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleLedOn,
              child: Text('Toggle LED On'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _toggleLedOff,
              child: Text('Toggle LED Off'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> connectToFirebase() async {
    try {
      LedRef.once().then((DatabaseEvent event) {
        DataSnapshot snapshot = event.snapshot;
        print('Connected to Firebase: ${snapshot.value}');
      });
    } catch (error) {
      print('Error connecting to Firebase: $error');
    }
  }
}

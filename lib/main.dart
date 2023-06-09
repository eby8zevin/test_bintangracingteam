import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothConnection? connection;
  List<String> dataList = [];

  @override
  void initState() {
    super.initState();

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      if (state == BluetoothState.STATE_OFF) {
        showSnackBar('Bluetooth is turned off');
      } else if (state == BluetoothState.STATE_ON) {
        showSnackBar('Bluetooth is turned on');
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    if (connection != null && connection!.isConnected) {
      showSnackBar('Already connected to a device. Disconnect first.');
      return;
    }

    try {
      BluetoothConnection newConnection =
          await BluetoothConnection.toAddress(device.address);
      showSnackBar('Connected to the device');
      setState(() {
        connection = newConnection;
      });
      listenForData();
    } catch (error) {
      showSnackBar('Failed to connect to the device. Please try again.');
    }
  }

  void listenForData() {
    connection!.input?.listen((data) {
      String decodedData = utf8.decode(data);
      if (decodedData.contains(';')) {
        List<String> values = decodedData.split(';');
        if (values.length == 8) {
          String crc = values[6];
          print(crc);
          setState(() {
            dataList = values.sublist(1, 6);
          });
        }
      }
    }).onDone(() {
      showSnackBar('Disconnected from the device');
      setState(() {
        connection = null;
        dataList.clear();
      });
    });
  }

  void disconnectFromDevice() {
    if (connection != null && connection!.isConnected) {
      connection!.close();
      showSnackBar('Disconnected from the device');
      setState(() {
        connection = null;
        dataList.clear();
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Connect to Device'),
              onPressed: () {
                showSnackBar('Searching for devices...');
                FlutterBluetoothSerial.instance
                    .openSettings()
                    .then((value) => print("value"));
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: disconnectFromDevice,
              child: const Text('Disconnect from Device'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Received Data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(dataList.join('\n')),
          ],
        ),
      ),
    );
  }
}

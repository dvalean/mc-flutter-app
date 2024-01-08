import 'dart:io';

import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class ESenseControls extends StatefulWidget {
  const ESenseControls({Key? key}) : super(key: key);

  @override
  _ESenseControlsState createState() => _ESenseControlsState();
}

class _ESenseControlsState extends State<ESenseControls> {
  late final ESenseManager eSenseManager;
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _deviceStatus = '';
  bool sampling = false;
  String _event = '';
  String _button = 'not pressed';
  bool connected = false;
  int _accelerometerX = 0; // To store accelerometer X-axis value

  @override
  void initState() {
    super.initState();
    eSenseManager = ESenseManager('eSense-0584');
    _listenToESense();
  }

  Future<void> _askForPermissions() async {
    if (!(await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted)) {
      print(
          'WARNING - no permission to use Bluetooth granted. Cannot access eSense device.');
    }
    // for some strange reason, Android requires permission to location for Bluetooth to work.....?
    if (Platform.isAndroid) {
      if (!(await Permission.locationWhenInUse.request().isGranted)) {
        print(
            'WARNING - no permission to access location granted. Cannot access eSense device.');
      }
    }
  }

  Future<void> _listenToESense() async {
    await _askForPermissions();

    eSenseManager.connectionEvents.listen((event) {
    print('CONNECTION event: $event');

    // when we're connected to the eSense device, we can start listening to events from it
    if (event.type == ConnectionType.connected) _listenToESenseEvents();

      setState(() {
        connected = false;
        switch (event.type) {
          case ConnectionType.connected:
            connected = true;
            break;
          case ConnectionType.disconnected:
            connected = false;
            break;
          case ConnectionType.unknown:
            // TODO: Handle this case.
          case ConnectionType.device_found:
            // TODO: Handle this case.
          case ConnectionType.device_not_found:
            // TODO: Handle this case.
        }
      });
    });
  }

  Future<void> _connectToESense() async {
    if (!connected) {
      print('Trying to connect to eSense device...');
      connected = await eSenseManager.connect();

      setState(() {
        _deviceStatus = connected ? 'connecting...' : 'connection failed';
      });
    }
  }

  void _listenToESenseEvents() async {
    eSenseManager.sensorEvents.listen((event) {
      print('ESENSE event: $event');

      setState(() {
        switch (event.runtimeType) {
          case DeviceNameRead:
            _deviceName = (event as DeviceNameRead).deviceName ?? 'Unknown';
            break;
          case BatteryRead:
            _voltage = (event as BatteryRead).voltage ?? -1;
            break;
          case ButtonEventChanged:
            _button = (event as ButtonEventChanged).pressed
                ? 'pressed'
                : 'not pressed';
            break;
          case AccelerometerOffsetRead:
            // TODO
            break;
          case AdvertisementAndConnectionIntervalRead:
            // TODO
            break;
          case SensorConfigRead:
            // TODO
            break;
        }

        // Handle accelerometer data using SensorEvent
        if (event is SensorEvent) {
          _accelerometerX = event.accel![0]; // X-axis accelerometer value
          _checkTiltDirection();
        }
        });
    });

    _getESenseProperties();
  }

  void _getESenseProperties() async {
    // get the battery level every 10 secs
    Timer.periodic(
      const Duration(seconds: 10),
      (timer) async =>
          (connected) ? await eSenseManager.getBatteryVoltage() : null,
    );

    // wait 2, 3, 4, 5, ... secs before getting the name, offset, etc.
    // it seems like the eSense BTLE interface does NOT like to get called
    // several times in a row -- hence, delays are added in the following calls
    Timer(const Duration(seconds: 2),
        () async => await eSenseManager.getDeviceName());
    Timer(const Duration(seconds: 3),
        () async => await eSenseManager.getAccelerometerOffset());
    Timer(
        const Duration(seconds: 4),
        () async =>
            await eSenseManager.getAdvertisementAndConnectionInterval());
    Timer(const Duration(seconds: 15),
        () async => await eSenseManager.getSensorConfig());
  }

  // Check if the device is tilted to the right or left
  void _checkTiltDirection() {
    // You can adjust this threshold value based on your requirement
    double tiltThreshold = 0.5;

    if (_accelerometerX > tiltThreshold) {
      print('Device tilted to the right');
      // TODO: Add your logic for right tilt
    } else if (_accelerometerX < -tiltThreshold) {
      print('Device tilted to the left');
      // TODO: Add your logic for left tilt
    } else {
      print('Device in a neutral position');
      // TODO: Add your logic for neutral position
    }
  }

  StreamSubscription? subscription;
  void _startListenToSensorEvents() async {
    // // any changes to the sampling frequency must be done BEFORE listening to sensor events
    // print('setting sampling frequency...');
    // await eSenseManager.setSamplingRate(100);

    // subscribe to sensor event from the eSense device
    subscription = eSenseManager.sensorEvents.listen((event) {
      print('SENSOR event: $event');
      setState(() {
        _event = event.toString();
      });
    });
    setState(() {
      sampling = true;
    });
  }

  void _pauseListenToSensorEvents() async {
    subscription?.cancel();
    setState(() {
      sampling = false;
    });
  }

  @override
  void dispose() {
    eSenseManager.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('eSense Device Status: \t$_deviceStatus'),
        Text('eSense Device Name: \t$_deviceName'),
        Text('eSense Battery Level: \t$_voltage'),
        Text('eSense Button Event: \t$_button'),
        Text('Connected: $connected'),
        ElevatedButton(
          onPressed: () => _connectToESense(),
          child: Text('Connect to eSense'),
        ),
        FloatingActionButton(
          onPressed: (!connected)
              ? null
              : (!sampling)
                  ? _startListenToSensorEvents
                  : _pauseListenToSensorEvents,
          tooltip: 'Listen to eSense sensors',
          child: (!sampling)
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause),
        ),
        // Other UI elements related to eSense controls...
      ],
    );
  }
}

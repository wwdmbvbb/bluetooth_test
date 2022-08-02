import 'package:bluetooth_test/discovery_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final permissions = [
    Permission.bluetooth,
    Permission.storage,
    Permission.location,
  ];

  final permissionsOver30 = [
    Permission.bluetoothAdvertise,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.storage,
    Permission.location,
  ];

  bool _rebuild = false;

  int? _androidSdk;

  @override
  void initState() {
    super.initState();
    final deviceInfoPlugin = DeviceInfoPlugin();
    deviceInfoPlugin.androidInfo.then((value) {
      if (kDebugMode) {
        print('got android info: $value');
      }
      setState(() {
        _androidSdk = value.version.sdkInt;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final chosenPerms = _androidSdk == null || _androidSdk! <= 30 ? permissions : permissionsOver30;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Test"),
      ),
      body: Column(
        children: [
          Text('Android Version: ${_androidSdk ?? 'unknown'}'),
          for (final p in permissions) _buildStatusTile(p),
          const Divider(),
          ElevatedButton(onPressed: _askPermission, child: const Text('Ask Permission')),
          ElevatedButton(onPressed: _scanBluetoothDevices, child: const Text('Scan Bluetooth')),
        ],
      ),
    );
  }

  Future<void> _askPermission() async {
    if (_androidSdk == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dont know SDK version!')));
      return;
    }
    final chosenPerms = _androidSdk! <= 30 ? permissions : permissionsOver30;
    for (final p in chosenPerms) {
      await p.request();
    }
    _onRebuildTiles();
  }

  Future<void> _scanBluetoothDevices() async {
    if (_androidSdk == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dont know SDK version!')));
      return;
    }
    final hasPermissions = _androidSdk! <= 30
        ? await Permission.bluetooth.status.isGranted
        : await Future.wait([
            Permission.bluetoothAdvertise.status,
            Permission.bluetoothScan.status,
            Permission.bluetoothConnect.status
          ]).then((statuses) => statuses.every((element) => element.isGranted));
    if (!hasPermissions) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: const Text('Need permission!')));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DiscoveryPage()));
  }

  _onRebuildTiles() {
    setState(() {
      _rebuild = !_rebuild;
    });
  }

  _buildStatusTile(Permission permission) {
    return ListTile(
      title: Text(permission.toString()),
      subtitle: FutureBuilder(
          key: Key('$permission$_rebuild'),
          future: permission.status,
          builder: (context, snapshot) => snapshot.hasData ? Text(snapshot.data.toString()) : const Text('...')),
    );
  }
}

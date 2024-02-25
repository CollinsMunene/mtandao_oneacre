import 'dart:async';
import 'dart:io';

import 'package:android_flutter_wifi/android_flutter_wifi.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_internet_signal/flutter_internet_signal.dart';
import 'package:mtandao_oneacre/widgets/networkcard.dart';
import 'package:mtandao_oneacre/widgets/wificard.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sim_data/sim_data.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  SimData? _simData;
  String _dataType = 'unknown';
  String _networkType = 'unknown';
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final NetworkInfo _networkInfo = NetworkInfo();
  int _mobileSignal = 0;
  int _wifiSignal = 0;
  int? _wifiSpeed;
  String? mobilesignalStrength;
  String? wifisignalStrength;

  final _internetSignal = FlutterInternetSignal();
  DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  String? _deviceData;

  String? wifiName;

  @override
  void initState() {
    super.initState();

    initConnectivity();
    initPlatformState();

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    String? deviceData;

    try {
      if (kIsWeb) {
        deviceData = null;
      } else {
        deviceData = switch (defaultTargetPlatform) {
          TargetPlatform.android =>
            _readAndroidBuildData(await deviceInfoPlugin.androidInfo),
          TargetPlatform.iOS => null,
          TargetPlatform.linux => null,
          TargetPlatform.macOS =>
            _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
          TargetPlatform.windows =>
            _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
          TargetPlatform.fuchsia => <String, dynamic>{
              'Error:': 'Fuchsia platform isn\'t supported'
            },
        } as String?;
      }
    } on PlatformException {
      deviceData = 'Error: Failed to get platform version';
    }

    if (!mounted) return;

    setState(() {
      _deviceData = deviceData;
    });
  }

  String _readAndroidBuildData(AndroidDeviceInfo build) {
    return build.display;
  }

  String _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    print('W');
    print(data);
    return data.deviceId;
  }

  String? _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    return data.systemGUID;
  }

  Future<void> initConnectivity() async {
    await AndroidFlutterWifi.init();
    var locationStatus = await Permission.location.status;
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      bool isGranted = await Permission.phone.request().isGranted;
      if (!isGranted) return;
    }

    if (locationStatus.isDenied) {
      await Permission.locationWhenInUse.request();
    }
    if (await Permission.location.isRestricted) {
      openAppSettings();
    }

    late ConnectivityResult result;
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print('Couldn\'t check connectivity status');
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.mobile) {
      _getInternetSignal();
      NetworkStatus networkStatus =
          await ConnectionNetworkType().currentNetworkStatus();
      switch (networkStatus) {
        case NetworkStatus.unreachable:
          // unreachable
          _networkType = 'unreachable';
        case NetworkStatus.wifi:
        // wifi
        case NetworkStatus.mobile2G:
          // 2G
          _networkType = '2G';
        case NetworkStatus.mobile3G:
          // 3G
          _networkType = '3G';
        case NetworkStatus.mobile4G:
          // 4G
          _networkType = '4G';
        case NetworkStatus.mobile5G:
          // 5G
          _networkType = '5G';
        case NetworkStatus.otherMobile:
          _networkType = 'other';
        // other connection
      }
      setState(() {
        _dataType = 'Mobile Data';
        _simData = null;
      });
      initMobileNumberState();
    } else if (result == ConnectivityResult.wifi) {
      if (await Permission.location.isGranted) {
        _getInternetSignal();
        wifiName = await _networkInfo.getWifiName();
      }

      setState(() {
        _dataType = 'WIFI';
        _simData = null;
      });

      initMobileNumberState();
    } else if (result == ConnectivityResult.other) {
      // Handle other types of connections if needed
    } else if (result == ConnectivityResult.none) {
      // Handle when not connected to any network
    }
  }

  Future<void> _getInternetSignal() async {
    // _getPlatformVersion();
    int? mobile;
    int? wifi;
    int? wifiSpeed;
    String? wstrength;
    String? mstrength;
    try {
      mobile = await _internetSignal.getMobileSignalStrength();
      wifi = await _internetSignal.getWifiSignalStrength();
      wifiSpeed = await _internetSignal.getWifiLinkSpeed();

      // Determine WiFi signal strength

      wstrength = await _getStrengthAsString(wifi ?? 0);

      // Determine mobile signal strength

      mstrength = await _getStrengthAsString(mobile ?? 0);
    } on PlatformException {
      if (kDebugMode) print('Error get internet signal.');
    }
    setState(() {
      _mobileSignal = mobile ?? 0;
      _wifiSignal = wifi ?? 0;
      _wifiSpeed = wifiSpeed;
      wifisignalStrength = wstrength;
      mobilesignalStrength = mstrength;
    });
  }

  Future<String> _getStrengthAsString(int signalStrength) async {
    signalStrength = signalStrength.abs();

    if (signalStrength >= 50 && signalStrength <= 79) {
      return 'Great';
    } else if (signalStrength >= 80 && signalStrength <= 89) {
      return 'Good';
    } else if (signalStrength >= 90 && signalStrength <= 99) {
      return 'Average';
    } else if (signalStrength >= 100 && signalStrength <= 109) {
      return 'Poor';
    } else if (signalStrength >= 110 && signalStrength <= 120) {
      return 'Very Poor';
    } else {
      return 'Unknown';
    }
  }

  Future<void> getWifiName() async {
    try {
      wifiName = await _networkInfo.getWifiBSSID();
    } on PlatformException catch (e) {
      print('Failed to get WiFi name: $e');
      wifiName = null;
    }
  }

  // Other methods remain unchanged

  Future<void> initMobileNumberState() async {
    SimData simData;

    try {
      simData = await SimDataPlugin.getSimData();
      // interfaces = simData.cards;
      setState(() {
        _simData = simData;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        _simData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          centerTitle: true,
          actions: <Widget>[
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert))
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        "Network and Signal Info",
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(child: Container()),
                      Text(
                        'Data Type: $_dataType',
                        style: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text('ID: ${_deviceData} \n'),
                  Text('Wifi signal: ${_wifiSignal ?? '--'} [dBm]\n'),
                  Text('Wifi speed: ${_wifiSpeed ?? '--'} Mbps\n'),
                  Text('Mobile signal: ${_mobileSignal ?? '--'} [dBm]\n'),
                  ElevatedButton(
                    onPressed: _getInternetSignal,
                    child: const Text('Update internet signal'),
                  ),
                  _dataType == 'WIFI'
                      ? WifiCard('WIFI - ${wifiName}', '', _wifiSignal,
                          _wifiSpeed, wifisignalStrength)
                      : SizedBox(
                          height: 10,
                        ),
                  Container(
                      height: 700,
                      child: ListView.builder(
                          itemCount: _simData?.cards.length,
                          itemBuilder: (context, index) {
                            return NetworkCard(
                                _networkType,
                                _simData?.cards[index].displayName,
                                _mobileSignal,
                                mobilesignalStrength);
                          })),
                ],
              )),
        ));
  }
}

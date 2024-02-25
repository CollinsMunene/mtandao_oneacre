import 'package:flutter/material.dart';
import 'package:mtandao_oneacre/enums/connectivity_status.dart';
import 'package:mtandao_oneacre/services/connectivity_service.dart';
import 'package:mtandao_oneacre/ui/home.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<ConnectivityStatus>(
      create: (context) =>
          ConnectivityService().connectionStatusController.stream,
      initialData: ConnectivityStatus.Offline,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mtandao OneAcre Fund',
        theme: ThemeData(brightness: Brightness.dark),
        home: const HomeView(),
      ),
    );
  }
}

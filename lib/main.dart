import 'package:Qibla/qiblah_compass.dart';
import 'package:Qibla/qiblah_maps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loading_indicator.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deviceSupport = FlutterQiblah.androidDeviceSensorSupport();
  String lat;
  String lon;
  int compassType;
  @override
  void initState() {
    _getCompassNum();
    super.initState();
  }

  _getCompassNum() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    compassType = prefs.getInt('compass');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          primaryColor: Color(0xff0c7b93),
          primaryColorLight: Color(0xff00a8cc),
          primaryColorDark: Color(0xff27496d),
          accentColor: Color(0xffecce6d),
          primaryTextTheme: TextTheme(
            title: TextStyle(
              color: Color(0xffecce6d),
            ),
          )),
      darkTheme: ThemeData.dark().copyWith(accentColor: Color(0xffecce6d)),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('The Qibla'),
        ),
        body: FutureBuilder(
          future: _deviceSupport,
          builder: (_, AsyncSnapshot<bool> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return LoadingIndicator();
            if (snapshot.hasError)
              return Center(
                child: Text("Error: ${snapshot.error.toString()}"),
              );

            if (snapshot.data)
              return QiblahCompass(compassType);
            else
              return QiblahMaps();
          },
        ),
      ),
    );
  }
}

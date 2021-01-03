import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'loading_indicator.dart';
import 'location_error_widget.dart';

class QiblahCompass extends StatefulWidget {
  final int compassType;

  QiblahCompass(this.compassType);

  @override
  _QiblahCompassState createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  get stream => _locationStreamController.stream;

  @override
  void initState() {
    _checkLocationStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8.0),
      child: StreamBuilder(
        stream: stream,
        builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return LoadingIndicator();
          if (snapshot.data.enabled == true) {
            switch (snapshot.data.status) {
              case LocationPermission.always:
              case LocationPermission.whileInUse:
                return QiblahCompassWidget(widget.compassType);

              case LocationPermission.denied:
                return LocationErrorWidget(
                  error: "Location service permission denied",
                  callback: _checkLocationStatus,
                );
              case LocationPermission.deniedForever:
                return LocationErrorWidget(
                  error: "Location service Denied Forever !",
                  callback: _checkLocationStatus,
                );
              // case GeolocationStatus.unknown:
              //   return LocationErrorWidget(
              //     error: "Unknown Location service error",
              //     callback: _checkLocationStatus,
              //   );
              default:
                return Container();
            }
          } else {
            return LocationErrorWidget(
              error: "Please enable Location service",
              callback: _checkLocationStatus,
            );
          }
        },
      ),
    );
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();
    if (locationStatus.enabled &&
        locationStatus.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else
      _locationStreamController.sink.add(locationStatus);
  }

  @override
  void dispose() {
    super.dispose();
    _locationStreamController.close();
    FlutterQiblah().dispose();
  }
}

class QiblahCompassWidget extends StatefulWidget {
  final int compassType;

  QiblahCompassWidget(this.compassType);

  @override
  _QiblahCompassWidgetState createState() => _QiblahCompassWidgetState();
}

class _QiblahCompassWidgetState extends State<QiblahCompassWidget> {
  int compassType;

  @override
  void initState() {
    compassType = widget.compassType;
    super.initState();
  }

  final _compassSvg = SvgPicture.asset(
    'assets/compass.svg',
  );

  final _needleSvg = SvgPicture.asset(
    'assets/needle.svg',
    fit: BoxFit.contain,
    height: 300,
    alignment: Alignment.center,
  );

  _compass() {
    if (compassType == 0 || compassType == null) return _compassSvg;
    if (compassType == 1) return Image(image: AssetImage('assets/1.png'));
    if (compassType == 2) return Image(image: AssetImage('assets/2.png'));
    if (compassType == 3) return Image(image: AssetImage('assets/3.png'));
    if (compassType == 4) return Image(image: AssetImage('assets/4.png'));
  }

  _setCompassNum(int num) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('compass', num);
    print(prefs.getInt('compass'));
  }

  _compassOptions(int num, String compass) {
    if (num == 0)
      return GestureDetector(
          onTap: () {
            _setCompassNum(num);

            setState(() {
              compassType = num;
            });
          },
          child: Container(
            height: 60,
            width: 60,
            child: SvgPicture.asset(
              compass,
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onTap: () {
          _setCompassNum(num);

          setState(() {
            compassType = num;
          });
        },
        child: Image(
          width: num == 2 ? 70 : 60,
          image: AssetImage(compass),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (_, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return LoadingIndicator();

        final qiblahDirection = snapshot.data;
        print(qiblahDirection.direction);
        print(qiblahDirection.qiblah);

        return Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Transform.rotate(
                    angle: ((qiblahDirection.direction ?? 0) * (pi / 180) * -1),
                    child: _compass(),
                  ),
                  Transform.rotate(
                    angle: ((qiblahDirection.qiblah ?? 0) * (pi / 180) * -1),
                    alignment: Alignment.center,
                    child: _needleSvg,
                  ),
                  compassType == 4
                      ? Align(
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: 10.0,
                          ),
                        )
                      : SizedBox.shrink()
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                children: [
                  Text("${qiblahDirection.offset.toStringAsFixed(3)}°"),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _compassOptions(0, 'assets/compass.svg'),
                        _compassOptions(1, 'assets/1.png'),
                        _compassOptions(2, 'assets/2.png'),
                        _compassOptions(3, 'assets/3.png'),
                        _compassOptions(4, 'assets/4.png'),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:slider_button/slider_button.dart';
import 'package:track_me/comm/android_comm.dart';
import 'package:track_me/history.dart';
import 'package:track_me/summary_page.dart';
import 'package:track_me/utils/lat_lng_wrapper.dart';

import 'db/database.dart';
import 'utils/android_call.dart';

const String METHOD_CHANNEL = "com.abarajithan.track_me/comm";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        primaryColor: Colors.lightBlue,
        primaryColorBrightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const methodChannel = const MethodChannel(METHOD_CHANNEL);
  bool isTrackingEnabled = false;
  bool isServiceBounded = false;
  AndroidComm androidComm = AndroidComm();

  String startTime = "N/a";
  Timer timer;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    _isServiceBound();
  }

  Future _isServiceBound() async {
    if (Platform.isAndroid) {
      bool result = await methodChannel.invokeMethod(AndroidCall.SERVICE_BOUND);
      setState(() {
        isServiceBounded = result;
      });
      if (result) {
        _isTrackingEnabled();
        _getStartTime();
      }
    }
  }

  Future _isTrackingEnabled() async {
    if (Platform.isAndroid) {
      bool result =
          await methodChannel.invokeMethod(AndroidCall.IS_TRACKING_ENABLED);
      setState(() {
        isTrackingEnabled = result;
      });
      if (result) {
        initTimer();
      }
    }
  }

  void initTimer() {
    timer = new Timer.periodic(Duration(seconds: 1), (t) async {
      final dataList = await getLatLngData();
      setState(() {
        polylines = {
          Polyline(
            polylineId: PolylineId(1.toString()),
            visible: true,
            points: dataList,
            color: Colors.blue,
            width: 6,
          )
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(padding: EdgeInsets.all(8), child: Text("Opensource 🎉️"))
          ],
        ),
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 64,
          title: Row(
            children: [
              Text(
                "Track",
                style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                "Me",
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.info,
                color: Colors.white,
              ),
              onPressed: () => _showAboutDialog(),
            )
          ],
        ),
        body: Builder(
          builder: (BuildContext context) {
            return Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                      Colors.lightBlue,
                      Colors.lightBlueAccent,
                      Colors.white
                    ])),
                child: SafeArea(
                  child: _getWidget(context),
                ));
          },
        ));
  }

  Widget _getWidget(BuildContext context) {
    return Container(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(children: [
              isTrackingEnabled
                  ? Container(
                      height: 300,
                      child: polylines.length == 0
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : GoogleMap(
                              myLocationEnabled: false,
                              zoomControlsEnabled: false,
                              compassEnabled: false,
                              rotateGesturesEnabled: false,
                              minMaxZoomPreference:
                                  MinMaxZoomPreference(15, 20),
                              initialCameraPosition: CameraPosition(
                                  target: polylines.first.points.last,
                                  zoom: 18),
                              polylines: polylines,
                            ),
                    )
                  : Text(
                      "Tracking disabled",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
            ]),
            Column(children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 250),
                child: isTrackingEnabled ? _SlideToStop() : _SlideToStart(),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(child: child, scale: anim),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: isTrackingEnabled
                    ? Text("Started at $startTime")
                    : RaisedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => TrackingHistory()));
                        },
                        child: Text(
                          "Previous sessions",
                          style: TextStyle(color: Colors.white),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.lightBlue,
                        padding: EdgeInsets.all(16)),
              )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _SlideToStop() {
    return SliderButton(
      action: () {
        timer.cancel();
        _startSummaryScreen();
      },
      label: Text("Slide to Stop"),
      icon: Center(
        child: Icon(
          Icons.close,
          color: Colors.white,
        ),
      ),
      buttonColor: Colors.lightBlue,
      shimmer: false,
      dismissible: false,
      vibrationFlag: false,
      backgroundColor: Colors.white,
      boxShadow: BoxShadow(color: Colors.lightBlue, blurRadius: 2),
    );
  }

  Widget _SlideToStart() {
    return SliderButton(
      action: () async {
        bool granted = await androidComm.hasProperPermission();
        if (granted) {
          _invokeAndroidService();
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(
            content: Text("Required All time location access"),
            action: SnackBarAction(
              onPressed: () => androidComm.showAppLocationSettings(),
              label: "Allow",
            ),
          ));
        }
      },
      label: Text("Slide to Track"),
      icon: Center(
        child: Icon(
          Icons.map,
          color: Colors.lightBlue,
        ),
      ),
      dismissible: false,
      vibrationFlag: false,
      backgroundColor: Colors.white,
      boxShadow: BoxShadow(color: Colors.lightBlue, blurRadius: 2),
    );
  }

  void _showAboutDialog() async {
    return showAboutDialog(
      context: context,
      applicationVersion: "v1.1.0",
      applicationIcon: new Image.asset(
        "assets/logo.png",
        height: 44,
        width: 44,
      ),
      children: [
        Text("No location data is transferred or stored anywhere."),
        Padding(
            padding: EdgeInsets.only(top: 16), child: Text("Made in India")),
      ],
    );
  }

  void _startSummaryScreen() async {
    setState(() {
      isTrackingEnabled = false;
    });
    int duration = await androidComm.stopAndroidService();
    final id = await insertSession(null, duration, polylines.first.points);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => SummaryPage(id: id)));
  }

  Future<List<LatLng>> getLatLngData() async {
    String json = await androidComm.getTrackedPoints();
    List<dynamic> jsonList = jsonDecode(json);
    List<LatLng> dataList = new List(jsonList.length);
    for (int i = 0; i < jsonList.length; i++) {
      dataList[i] = LatLngWrapper.fromAndroidJson(jsonList[i]);
    }
    return dataList;
  }

  void _invokeAndroidService() async {
    String time = await androidComm.invokeAndroidService();
    initTimer();
    setState(() {
      isTrackingEnabled = true;
      startTime = time;
    });
  }

  void _getStartTime() async {
    String time = await androidComm.getStartTime();
    setState(() {
      startTime = time;
    });
  }
}

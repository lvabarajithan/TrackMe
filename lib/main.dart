import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:slider_button/slider_button.dart';
import 'package:track_me/comm/android_comm.dart';
import 'package:track_me/summary_page.dart';
import 'package:track_me/utils/lat_lng_wrapper.dart';

import 'utils/android_call.dart';

const String METHOD_CHANNEL = "com.abarajithan.track_me/comm";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackMe',
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
    }
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
              Text(
                isTrackingEnabled
                    ? "Tracking your movements.."
                    : "Tracking disabled",
                style: TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              if (isTrackingEnabled)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Started at $startTime",
                    style: TextStyle(color: Colors.white),
                  ),
                )
            ]),
            !isTrackingEnabled
                ? SliderButton(
                    action: () async {
                      bool granted = await androidComm.hasProperPermission();
                      if (granted) {
                        _invokeAndroidService();
                      } else {
                        Scaffold.of(context).showSnackBar(SnackBar(
                          content: Text("Required All time location access"),
                          action: SnackBarAction(
                            onPressed: () =>
                                androidComm.showAppLocationSettings(),
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
                    boxShadow:
                        BoxShadow(color: Colors.lightBlue, blurRadius: 2),
                  )
                : Column(
                    children: [
                      SliderButton(
                        action: () {
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
                        boxShadow:
                            BoxShadow(color: Colors.lightBlue, blurRadius: 2),
                      ),
                      Padding(
                          padding: EdgeInsets.all(16),
                          child: Text("Tracking summary is shown once stopped"))
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() async {
    return showAboutDialog(
      context: context,
      applicationVersion: "v1.0.0",
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
    String json = await androidComm.stopAndroidService();
    List<dynamic> jsonList = jsonDecode(json);
    List<LatLng> dataList = new List(jsonList.length);
    for (int i = 0; i < jsonList.length; i++) {
      dataList[i] = LatLngWrapper.fromAndroidJson(jsonList[i]);
    }
    setState(() {
      isTrackingEnabled = false;
    });
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => SummaryPage(dataList)));
  }

  void _invokeAndroidService() async {
    String time = await androidComm.invokeAndroidService();
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

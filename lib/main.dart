import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slider_button/slider_button.dart';
import 'package:track_me/comm/android_comm.dart';
import 'package:track_me/summary_page.dart';
import 'package:track_me/utils/lat_lng_wrapper.dart';

import 'db/database.dart';
import 'history.dart';
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
        cardTheme: CardTheme(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: EdgeInsets.all(16),
          elevation: 6,
        ),
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

  LatLng currLocation;

  @override
  void initState() {
    super.initState();
    _isServiceBound();
    _initCurrLocation();
  }

  void _initCurrLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("cached_loc")) {
      final json = jsonDecode(prefs.getString("cached_loc"));
      currLocation = LatLngWrapper.fromAndroidJson(json);
    } else {
      currLocation = LatLng(0, 0);
    }
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
    return Scaffold(body: Builder(
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
    return Stack(
      children: [
        currLocation == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : GoogleMap(
                onMapCreated: (controller) async {
                  final style = await DefaultAssetBundle.of(context)
                      .loadString("assets/mapstyle.json");
                  controller.setMapStyle(style);
                  setUserLocation(controller);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: false,
                minMaxZoomPreference: MinMaxZoomPreference(15, 25),
                initialCameraPosition:
                    CameraPosition(target: currLocation, zoom: 17),
                polylines: polylines,
              ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Card(
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        "TrackMe",
                        style: TextStyle(
                          fontSize: 24,
                          fontStyle: FontStyle.italic,
                        ),
                      )),
                ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    child: IconButton(
                      icon: Icon(
                        Icons.info,
                      ),
                      onPressed: () => _showAboutDialog(),
                    ),
                  ),
                )
              ],
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
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
                                    builder: (context) => TrackingHistory()),
                              );
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
              ),
            )
          ],
        )
      ],
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
      backgroundColor: Colors.grey.shade200,
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
      backgroundColor: Colors.grey.shade200,
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
        Text(
            "Your location data never leaves the device. App respects privacy."),
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

  void setUserLocation(GoogleMapController controller) async {
    final data = await new Location().getLocation();
    currLocation = LatLng(data.latitude, data.longitude);
    controller.animateCamera(CameraUpdate.newLatLng(currLocation));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("cached_loc", jsonEncode(currLocation));
  }
}

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SummaryPage extends StatefulWidget {
  final List<LatLng> data;

  SummaryPage(this.data);

  @override
  _SummaryPage createState() => _SummaryPage(data);
}

class _SummaryPage extends State<SummaryPage> {
  final Set<Polyline> _polylines = {};
  final List<LatLng> data;

  _SummaryPage(this.data) {
    _showInMap();
  }

  void _showInMap() async {
    data.forEach((latlng) {
      _polylines.add(Polyline(
        polylineId: PolylineId(latlng.toString()),
        visible: true,
        points: data,
        color: Colors.blue,
        width: 6,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        centerTitle: true,
        title: Text(
          "Tracking Summary",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        child: (data.length != 0)
            ? GoogleMap(
                myLocationEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                rotateGesturesEnabled: false,
                minMaxZoomPreference: MinMaxZoomPreference(15, 20),
                initialCameraPosition:
                    CameraPosition(target: data.first, zoom: 18),
                polylines: _polylines)
            : Center(
                child: Text("Invalid tracking data :("),
              ),
      ),
    );
  }
}

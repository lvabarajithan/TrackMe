import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:track_me/db/database.dart';

class SummaryPage extends StatefulWidget {
  final int id;
  final String title;

  SummaryPage({this.id, this.title});

  @override
  _SummaryPage createState() => _SummaryPage(sessionId: id, title: title);
}

class _SummaryPage extends State<SummaryPage> {
  GoogleMapController _controller;

  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  String title;
  final int sessionId;

  _SummaryPage({this.sessionId, this.title});

  @override
  void initState() {
    super.initState();
    _showInMap();
  }

  void _showInMap() {
    getLocationPoints(sessionId).then((value) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId(1.toString()),
            visible: true,
            points: value,
            color: Colors.blue,
            width: 6,
          )
        };
        _markers = {
          Marker(
            markerId: MarkerId("start"),
            position: value.first,
            infoWindow: InfoWindow(title: "You started here"),
            consumeTapEvents: false,
            flat: true,
          ),
          Marker(
            markerId: MarkerId("end"),
            position: value.last,
            infoWindow: InfoWindow(title: "Destination"),
          ),
        };
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            child: (_polylines.length != 0)
                ? GoogleMap(
                    onMapCreated: (controller) async {
                      _controller = controller;
                      final style = await DefaultAssetBundle.of(context)
                          .loadString("assets/mapstyle.json");
                      controller.setMapStyle(style);
                    },
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    rotateGesturesEnabled: false,
                    minMaxZoomPreference: MinMaxZoomPreference(15, 20),
                    initialCameraPosition: CameraPosition(
                        target: _polylines.first.points.first, zoom: 18),
                    polylines: _polylines,
                    markers: _markers,
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: InkWell(
                      child: Icon(Icons.arrow_back_ios),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      title ?? "Tracking Summary",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller.dispose();
    }
    super.dispose();
  }
}

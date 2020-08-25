import 'package:google_maps_flutter/google_maps_flutter.dart';

class LatLngWrapper {
  static LatLng fromAndroidJson(dynamic json) {
    return LatLng(json[0], json[1]);
  }
}

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:track_me/utils/android_call.dart';

const String METHOD_CHANNEL = "com.abarajithan.track_me/comm";

class AndroidComm {
  MethodChannel _methodChannel = MethodChannel(METHOD_CHANNEL);

  Future invokeAndroidService() {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod(AndroidCall.START_TRACKING);
    }
  }

  Future<int> stopAndroidService() async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod(AndroidCall.STOP_TRACKING);
    }
  }

  Future getTrackedPoints() async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod(AndroidCall.GET_TRACKED_POINTS);
    }
  }

  Future getStartTime() async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod(AndroidCall.START_TIME);
    }
  }

  Future isTrackingEnabled() async {
    if (Platform.isAndroid) {
      bool result =
          await _methodChannel.invokeMethod(AndroidCall.IS_TRACKING_ENABLED);
      return result;
    }
  }

  Future isServiceBound() async {
    if (Platform.isAndroid) {
      bool result =
          await _methodChannel.invokeMethod(AndroidCall.START_TRACKING);
      if (result) {
        isTrackingEnabled();
      }
    }
  }

  Future hasProperPermission() async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod(AndroidCall.HAS_PROPER_PERMISSION);
    }
  }

  void showAppLocationSettings() {
    if (Platform.isAndroid) {
      _methodChannel.invokeMethod(AndroidCall.LAUNCH_APP_SETTINGS);
    }
  }
}

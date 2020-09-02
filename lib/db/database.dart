import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Session {
  int id;
  final int timestamp;
  final String name;

  Session({this.timestamp, this.name, this.id});

  Map<String, dynamic> toMap() {
    return {"timestamp": timestamp, "name": name};
  }
}

class LocationPoint {
  int id;
  final int sessionId;
  final double latitude;
  final double longitude;

  LocationPoint({this.sessionId, this.latitude, this.longitude});

  Map<String, dynamic> toMap() {
    return {
      "sessionId": sessionId,
      "latitude": latitude,
      "longitude": longitude
    };
  }
}

Future<Database> getDatabase() async =>
    openDatabase(join(await getDatabasesPath(), "locations.db"),
        onCreate: createDatabase, version: 1);

void createDatabase(db, version) {
  db.execute("CREATE TABLE sessions(" +
      "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
      "timestamp INTEGER, " +
      "name TEXT)");
  db.execute("CREATE TABLE location_points(" +
      "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
      "sessionId INTEGER, " +
      "latitude REAL, " +
      "longitude REAL)");
}

Future<String> insertSession(String sessionName, List<LatLng> points) async {
  final Database db = await getDatabase();
  return db.transaction((txn) async {
    final List<Map<String, dynamic>> listData =
        await txn.query("sessions", columns: ["id"]);
    final int count = listData.length == 0 ? 1 : listData.last["id"] + 1;

    final name = sessionName ?? "Session $count";
    Session session = Session(
        timestamp: new DateTime.now().millisecondsSinceEpoch, name: name);
    final int id = await txn.insert("sessions", session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    points.forEach((latLng) async {
      LocationPoint point = LocationPoint(
          sessionId: id,
          latitude: latLng.latitude,
          longitude: latLng.longitude);
      await txn.insert("location_points", point.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return name;
  });
}

Future getSessions() async {
  final Database db = await getDatabase();
  final data = await db.query("sessions", orderBy: "timestamp");
  List<Session> sessions = [];
  data.forEach((item) {
    sessions.add(Session(
        id: item["id"], timestamp: item["timestamp"], name: item["name"]));
  });
  return sessions;
}

Future getLocationPoints(int sessionId) async {
  final Database db = await getDatabase();
  final data = await db
      .query("location_points", where: "sessionId = ?", whereArgs: [sessionId]);
  List<LatLng> points = [];
  data.forEach((item) {
    points.add(LatLng(item["latitude"], item["longitude"]));
  });
  return points;
}

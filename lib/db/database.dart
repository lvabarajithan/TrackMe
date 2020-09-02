import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Session {
  int id;
  final int timestamp;
  final int duration;
  final String name;

  Session({this.timestamp, this.duration, this.name, this.id});

  Map<String, dynamic> toMap() {
    return {"timestamp": timestamp, "duration": duration, "name": name};
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
      "duration INTEGER, " +
      "name TEXT)");
  db.execute("CREATE TABLE location_points(" +
      "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
      "sessionId INTEGER, " +
      "latitude REAL, " +
      "longitude REAL)");
}

Future<int> insertSession(
    String sessionName, int duration, List<LatLng> points) async {
  final Database db = await getDatabase();
  return db.transaction((txn) async {
    final List<Map<String, dynamic>> listData =
        await txn.query("sessions", columns: ["id"]);
    final int count = listData.length == 0 ? 1 : listData.last["id"] + 1;

    Session session = Session(
        timestamp: new DateTime.now().millisecondsSinceEpoch,
        duration: duration,
        name: sessionName ?? "Session $count");
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
    return id;
  });
}

Future getSessions() async {
  final Database db = await getDatabase();
  final data = await db.query("sessions", orderBy: "timestamp");
  List<Session> sessions = [];
  data.forEach((item) {
    sessions.add(Session(
        id: item["id"],
        timestamp: item["timestamp"],
        duration: item["duration"],
        name: item["name"]));
  });
  await db.close();
  return sessions;
}

Future<List<LatLng>> getLocationPoints(int sessionId) async {
  final Database db = await getDatabase();
  final data = await db
      .query("location_points", where: "sessionId = ?", whereArgs: [sessionId]);
  List<LatLng> points = [];
  data.forEach((item) {
    points.add(LatLng(item["latitude"], item["longitude"]));
  });
  await db.close();
  return points;
}

Future<bool> deleteSession(int id) async {
  final Database db = await getDatabase();
  final deletedId = await db.delete("sessions", where: "id=?", whereArgs: [id]);
  await db.close();
  return deletedId == 1;
}

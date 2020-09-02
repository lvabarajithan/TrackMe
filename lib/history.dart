import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:track_me/db/database.dart';
import 'package:track_me/summary_page.dart';

class TrackingHistory extends StatefulWidget {
  @override
  _TrackingHistoryState createState() => _TrackingHistoryState();
}

class _TrackingHistoryState extends State<TrackingHistory> {
  List<Session> sessions;
  Map<int, List<Polyline>> polylines;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  void loadSessions() async {
    List<Session> sessionData = await getSessions();
    setState(() {
      sessions = sessionData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: Brightness.dark,
        centerTitle: true,
        title: Text(
          "Previous Sessions",
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
      body: sessions == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : sessions.length == 0
              ? Center(
                  child: Text("No tracking sessions"),
                )
              : ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (c, index) {
                    final session = sessions[index];
                    final date =
                        DateTime.fromMillisecondsSinceEpoch(session.timestamp);
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: InkWell(
                        onTap: () async {
                          List<LatLng> data =
                              await getLocationPoints(session.id);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SummaryPage(
                                      title: session.name, data: data)));
                        },
                        child: ListTile(
                          title: Text(session.name),
                          subtitle: Text(date.toLocal().toString()),
                          trailing: IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _deleteSession(index, session.id)),
                        ),
                      ),
                    );
                  }),
    );
  }

  void _deleteSession(int index, int id) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete"),
            content: Text("Are you sure to delete this session?"),
            actions: [
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black45),
                  )),
              FlatButton(
                  onPressed: () async {
                    final success = await deleteSession(id);
                    if (success) {
                      setState(() {
                        sessions.removeAt(index);
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Delete",
                    style: TextStyle(color: Colors.redAccent),
                  ))
            ],
          );
        });
  }
}

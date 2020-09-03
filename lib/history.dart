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
                    final durationText =
                        "${Duration(milliseconds: session.duration).inMinutes}min";
                    return Dismissible(
                      confirmDismiss: (d) =>
                          _showConfirmDialog(index, session.id),
                      key: Key(session.id.toString()),
                      onDismissed: (d) async {
                        final success = await deleteSession(session.id);
                        if (success) {
                          setState(() {
                            sessions.removeAt(index);
                          });
                        }
                      },
                      background: swipeBackground(Alignment.centerLeft),
                      secondaryBackground:
                          swipeBackground(Alignment.centerRight),
                      child: InkWell(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SummaryPage(
                                    id: session.id,
                                    title: "${session.name} • $durationText"))),
                        child: ListTile(
                          title: Row(
                            children: [
                              Text(
                                session.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Icon(
                                Icons.timer,
                                size: 14,
                              ),
                              Text(
                                durationText,
                                style: TextStyle(
                                    fontStyle: FontStyle.italic, fontSize: 15),
                              )
                            ],
                          ),
                          subtitle: Text(
                            date.toLocal().toString(),
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: IconButton(
                              icon: Icon(
                                Icons.edit,
                              ),
                              onPressed: () async {
                                final shouldEdit =
                                    await _showEditDialog(session);
                                if (shouldEdit) {
                                  _editItem(session, index);
                                }
                              }),
                        ),
                      ),
                    );
                  }),
    );
  }

  Widget swipeBackground(Alignment alignment) {
    return Container(
      color: Colors.redAccent,
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String sessionEditName;

  Future<bool> _showEditDialog(Session session) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) {
          return AlertDialog(
            title: Text("Change name"),
            content: TextField(
              decoration: InputDecoration(hintText: session.name),
              onChanged: (text) {
                setState(() {
                  sessionEditName = text;
                });
              },
            ),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black45),
                  )),
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    "Save",
                    style: TextStyle(color: Colors.redAccent),
                  ))
            ],
          );
        });
  }

  void _editItem(Session session, int index) async {
    final success = await changeSessionName(session.id, sessionEditName);
    if (success) {
      setState(() {
        sessions[index].name = sessionEditName;
      });
    }
  }

  Future<bool> _showConfirmDialog(int index, int id) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete"),
            content: Text("Are you sure to delete this session?"),
            actions: [
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.black45),
                  )),
              FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
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

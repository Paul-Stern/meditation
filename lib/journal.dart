// import 'package:flutter/widgets.dart';
import 'package:meditation/session.dart';
import 'package:meditation/db.dart';
import 'package:flutter/material.dart';

// import 'package:sqflite/sqflite.dart';

class JournalWidget extends StatefulWidget {
  const JournalWidget({Key? key}) : super(key: key);

  @override
  State<JournalWidget> createState() => _JournalWidgetState();

}

class _JournalWidgetState extends State<JournalWidget> {

  List<Session> sessions = [];
  DatabaseHelper db = DatabaseHelper.instance;

  // init state
  // @override
  // void initState(){
  //   super.initState();
  //   db = DatabaseHelper();
  //   sessions = await db!.getSessions();
  // }

  @override
  void initState() {
    super.initState();
    db = DatabaseHelper.instance;
  }

  FutureBuilder<List<Session>> buildSessionList() {
    return FutureBuilder<List<Session>>(
      future: db.getSessions(),
      builder: (BuildContext context, AsyncSnapshot<List<Session>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(snapshot.data![index].started.toString()!),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  // define ListTile
  ListView buildSessionListView() {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (BuildContext context, int index) {
        return ListTile(
          title: Text(sessions[index].message!),
        );
      },
    );
  }
 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
      ),
      body: buildSessionList()
    );
  }
}
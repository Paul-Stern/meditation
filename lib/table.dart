// import 'package:flutter/widgets.dart';
import 'package:meditation/details.dart';
import 'package:meditation/session.dart';
import 'package:meditation/db.dart';
import 'package:flutter/material.dart';
import 'package:meditation/data.dart';
import 'package:meditation/utils.dart' as u;

// import 'package:sqflite/sqflite.dart';

class TableWidget extends StatefulWidget {
  const TableWidget({Key? key}) : super(key: key);

  @override
  State<TableWidget> createState() => _TableWidgetState();

}

class _TableWidgetState extends State<TableWidget> {

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
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const <DataColumn>[
                DataColumn(
                  label: Text(
                    'Started',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              DataColumn(
                  label: Text(
                    'Duration',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              rows: snapshot.data!
                  .map(
                    (session) => DataRow(
                      cells: <DataCell>[
                        DataCell(
                          Card(
                            child: InkWell(
                              child: Text(toLocalTime(session.started).toString()),
                              onTap: 
                                () => {
                                  u.log.d('Row was tapped!'),
                                  showDialog(
                                    context: context,
                                    builder: 
                                      (BuildContext context) => DetailsWidget(session: session)
                                    )
                              }
                              )
                          ),
                        ),
                        DataCell(Text(formatDuration(toDuration(session.duration)))),
                      ],
                    ),
                  )
                  .toList(),
            )
          );

          // return ListView.builder(
          //   itemCount: snapshot.data!.length,
          //   itemBuilder: (BuildContext context, int index) {
          //     return ListTile(
          //       title: Text(snapshot.data![index].started.toString()),

          //     );
          //   },
          // );
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
    return Card(
      child: buildSessionList(),
    );
  }
}
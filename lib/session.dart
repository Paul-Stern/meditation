import 'package:meditation/utils.dart';

class Session {
  final int id;
  final DateTime started;
  final DateTime ended;
  final Duration duration;
  final String message;

  Session({
    required this.id,
    required this.started, 
    required this.ended, 
    required this.duration, 
    required this.message,
});

  // Convert a Session to Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started': started.millisecondsSinceEpoch,
      'ended': ended.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'message': message,
    };
  }
  Session.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        started = DateTime.fromMillisecondsSinceEpoch(map['started']),
        ended = DateTime.fromMillisecondsSinceEpoch(map['ended']),
        duration = Duration(milliseconds: map['duration']),
        message = map['message'];


  // define toString method
  @override
  String toString() {
    final String d = formatDuration(duration);
    return 'id: $id\nstarted: $started\nended: $ended\nduration: $d\nmessage: $message';
  }
  // gets a session from a csv row
  static Session fromCsv(List<dynamic> row) {
    final dstring = row[1].split(':');
    var d = Duration();
    if (dstring.length == 2) {
    d = Duration(
      hours: int.parse(dstring[0]),
      minutes: int.parse(dstring[1]),
    );
    } else if (dstring.length == 3) {
       d = Duration(
        hours: int.parse(row[1].split(':')[0]),
        minutes: int.parse(row[1].split(':')[1]),
        seconds: int.parse(row[1].split(':')[2]),
      );
    } else {
      // wrong format
      log.e('wrong duration format');
    }

    // check row[0] type
    var id = 0;
    if (row[0].runtimeType != int) {
      id = int.parse(row[0]);
    } else {
      id = row[0];
    }

    final s = Session(
      id: id,
      duration: d,
      started: DateTime.parse(row[2]),
      ended: DateTime.parse(row[3]),
      message: row[4]
    );
    log.d('session from csv: $s');
    return s;
  }
  // format For export
  String formatForExport() {
    final String d = formatDuration(duration);
    return '$id,$d,$started,$ended,$message';
  }
  String DateTimeToString(DateTime d) {
    return "${d.year}-${d.month}-${d.day}";
  }
}

// toLocalTime helper function
DateTime toLocalTime(int unixTime) {
  return DateTime.fromMillisecondsSinceEpoch(unixTime);
}
Duration toDuration(int unixTime) {
  return Duration(milliseconds: unixTime);
}
String formatDuration(Duration d) {
  // log.d("d: $d");
  String hours = d.inHours.toString().padLeft(1, '0');
  String min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  String sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return "$hours:$min:$sec";
}
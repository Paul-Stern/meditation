import 'package:meditation/utils.dart';

class Session {
  final int id;
  final int started;
  final int ended;
  final int duration;
  final String message;
  final int streakdays;

  Session({
    required this.id,
    required this.started, 
    required this.ended, 
    required this.duration, 
    required this.message,
    required this.streakdays
});

  // Convert a Session to Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started': started,
      'ended': ended,
      'duration': duration,
      'message': message,
      'streakdays': streakdays
    };
  }
  Session.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        started = map['started'],
        ended = map['ended'],
        duration = map['duration'],
        message = map['message'],
        streakdays = map['streakdays'];

  // define toString method
  String toString() {
    return 'id: $id\nstarted: $started\nended: $ended\nduration: $duration\nmessage: $message\nstreakdays: $streakdays';
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
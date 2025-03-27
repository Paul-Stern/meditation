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
}

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
}
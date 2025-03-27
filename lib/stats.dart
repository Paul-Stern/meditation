import 'package:flutter/material.dart';

class StatsWidget extends StatefulWidget {
  const StatsWidget({super.key});

  @override
  State<StatsWidget> createState() => _StatsWidgetState();
}

class _StatsWidgetState extends State<StatsWidget> {
  DateTime timestamp = DateTime.now();
  int streakdays = 0;
  int totaldays = 0;
  Duration totaltime = Duration.zero;

  String getTotalTime() {
    String hours = totaltime.inHours.toString();
    String min = totaltime.inMinutes.remainder(60).toString();
    // String sec = totaltime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours h $min m";
  }

 

  @override
  Widget build(BuildContext context) {
    return Card(
        child: SizedBox.expand(
          child: Center(
            child: Column(
              children: [
                Text("Total time: ${getTotalTime()}"),
                Text("Total days: ${totaldays}"),
                Text("Streak days: ${streakdays}"),
              ],
            ),
          ),
        ),
      );
  }
}
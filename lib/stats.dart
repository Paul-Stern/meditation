import 'package:flutter/material.dart';
import 'package:meditation/journal.dart';

class StatsWidget extends StatefulWidget {
  const StatsWidget({Key? key}) : super(key: key);

  @override
  State<StatsWidget> createState() => _StatsState();
}

class _StatsState extends State<StatsWidget> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: Column(
        children: [
          Text("Total time: ${getTotalTime()}"),
          Text("Total days: $totaldays"),
          Text("Streak: $streakdays"),
          TextButton(
            child: const Text("Details"),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const JournalWidget()));
            },
          )
        ],
      )
    );
  }
}
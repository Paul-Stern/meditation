import 'package:flutter/material.dart';
import 'package:meditation/table.dart';
import 'package:meditation/stats.dart';

class DataWidget extends StatefulWidget {
  const DataWidget({Key? key}) : super(key: key);

  @override
  State<DataWidget> createState() => _DataState();
}

class _DataState extends State<DataWidget> {
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
      body:
          NavigationBar(
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Details',
              ),
            ],
            onDestinationSelected: (int index) {
              if (index == 0) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StatsWidget()));
              }
              if (index == 1) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TableWidget()));
              }
            },  
          ),
    );
  }
}
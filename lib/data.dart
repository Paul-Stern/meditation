import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:meditation/table.dart';
import 'package:meditation/stats.dart';

class DataWidget extends StatefulWidget {
  const DataWidget({Key? key}) : super(key: key);

  @override
  State<DataWidget> createState() => _DataState();
}

class _DataState extends State<DataWidget> with TickerProviderStateMixin{
  DateTime timestamp = DateTime.now();
  int streakdays = 0;
  int totaldays = 0;
  Duration totaltime = Duration.zero;
  // late Ticker ticker;
  late final TabController _tabController;
  // TabController? _tabController;

  String getTotalTime() {
    String hours = totaltime.inHours.toString();
    String min = totaltime.inMinutes.remainder(60).toString();
    // String sec = totaltime.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$hours h $min m";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Overview'),
            Tab(text: 'Table'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StatsWidget(),
          TableWidget(),
        ],
      ),
   );
  }
}
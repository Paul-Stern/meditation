import 'package:flutter/widgets.dart';
import 'package:meditation/session.dart';

class JournalWidget extends StatefulWidget {
  const JournalWidget({Key? key}) : super(key: key);

  @override
  State<JournalWidget> createState() => _JournalWidgetState();

}

class _JournalWidgetState extends State<JournalWidget> {

  List<Session> sessions = [];

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
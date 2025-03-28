import 'package:flutter/material.dart';
import 'package:meditation/session.dart';

class DetailsWidget extends StatefulWidget {
  final Session session;

  const DetailsWidget({Key? key, required this.session}) : super(key: key);

  @override
  _DetailsWidgetState createState() => _DetailsWidgetState();
}

class _DetailsWidgetState extends State<DetailsWidget> {

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Details"),
      content: Text(widget.session.toString()),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
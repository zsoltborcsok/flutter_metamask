import 'package:flutter/material.dart';

Future<String> showApproveDialog(
    BuildContext context, String title, List<Widget> content,
    {String approveText = 'Approve', String cancelText = 'Cancel'}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: content,
          ),
        ),
        actions: <Widget>[
          ButtonBar(children: <Widget>[
            FlatButton(
              textColor: Theme.of(context).primaryColor,
              child: Text(
                cancelText,
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            FlatButton(
              color: Theme.of(context).primaryColor,
              textColor: Colors.white,
              child: Text(
                approveText,
                style: TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.pop(context, approveText);
              },
            ),
          ])
        ],
      );
    },
  );
}

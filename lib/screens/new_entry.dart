import 'package:flutter/material.dart';

class NewEntryScreen extends StatefulWidget {
  const NewEntryScreen({super.key});

  @override
  State<NewEntryScreen> createState() {
    return _NewEntryScreenState();
  }
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("_NewEntryScreenState widget"));
  }
}

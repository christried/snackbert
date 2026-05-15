import 'package:flutter/material.dart';

// basically the "surroundings" containing the appbar, bottomnavigationbar and (maybe if necessary in the future) a drawer
// has a dynamic title in appbar depending on active screen
// has bottomnavigationbar with 2 options: "Eintragen" and "Übersicht"

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.abc),
          label: "BottomNavigationBar hier",
        ),
      ],
    );
  }
}

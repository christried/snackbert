import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:snackbert/screens/auth.dart';
import 'package:snackbert/screens/new_entry.dart';
import 'package:snackbert/screens/overview.dart';
import 'package:snackbert/utils/snackbar.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key});

  @override
  ConsumerState<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
  // Page Selection
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void _onTapLogOut() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthScreen()));
    showAppSnackBar(context, "Bis zum nächsten Mal!");
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget activePage = const NewEntryScreen();
    var activePageTitle = "Neuer Eintrag";

    if (_selectedPageIndex == 1) {
      activePage = OverviewScreen();
      activePageTitle = "Deine Übersicht";
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(activePageTitle),
        backgroundColor: colors.secondaryContainer,
        actions: [
          IconButton.filled(
            onPressed: () {
              _onTapLogOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPageIndex,
        onTap: _selectPage,
        selectedFontSize: 16,
        selectedItemColor: const Color.fromARGB(183, 0, 0, 0),
        backgroundColor: colors.secondaryContainer,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "Eintragen"),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: "Übersicht",
          ),
        ],
      ),
    );
  }
}

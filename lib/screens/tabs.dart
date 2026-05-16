import 'package:flutter/material.dart';
import 'package:snackbert/screens/auth.dart';
import 'package:snackbert/screens/new_entry.dart';
import 'package:snackbert/screens/overview.dart';
import 'package:snackbert/services/auth_service.dart';

// basically the "surroundings" containing the appbar, bottomnavigationbar and (maybe if necessary in the future) a drawer
// has a dynamic title in appbar depending on active screen
// has bottomnavigationbar with 2 options: "Eintragen" and "Übersicht"

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends State<TabsScreen> {
  @override
  void initState() {
    super.initState();
    // When the service reports sign-out, go back to AuthScreen.
    widget.authService.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    if (!widget.authService.isSignedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AuthScreen(authService: widget.authService),
        ),
      );
    }
  }

  // Page Selection
  int _selectedPageIndex = 0;

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget activePage = NewEntryScreen();
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
            onPressed: widget.authService.signOut,
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: activePage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedPageIndex,
        onTap: _selectPage,
        selectedFontSize: 16,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/providers/meals_provider.dart';
import 'package:snackbert/screens/auth.dart';
import 'package:snackbert/screens/new_entry.dart';
import 'package:snackbert/screens/overview.dart';
import 'package:snackbert/services/auth_service.dart';

class TabsScreen extends ConsumerStatefulWidget {
  const TabsScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  ConsumerState<TabsScreen> createState() {
    return _TabsScreenState();
  }
}

class _TabsScreenState extends ConsumerState<TabsScreen> {
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
      final meals = ref.watch(mealsProvider);

      activePage = OverviewScreen(meals: meals);
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

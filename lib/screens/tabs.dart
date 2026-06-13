import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snackbert/data/snackbert_messages.dart';
import 'package:snackbert/providers/audio_recording_provider.dart';
import 'package:snackbert/providers/meal_submitting_provider.dart';

import 'package:snackbert/screens/new_entry.dart';
import 'package:snackbert/screens/overview.dart';
import 'package:snackbert/services/update_service.dart';
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

  @override
  void initState() {
    super.initState();
    _setupUpdateCheck();
  }

  void _setupUpdateCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });

    // App opened from a notification tap (background state)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.data['type'] == 'update' && mounted) {
        UpdateService.showUpdateDialog(context);
      }
    });

    // App opened from a notification tap (terminated state)
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message?.data['type'] == 'update' && mounted) {
        UpdateService.showUpdateDialog(context);
      }
    });
  }

  void _selectPage(int index) {
    setState(() {
      _selectedPageIndex = index;
    });
  }

  void _onTapLogOut() {
    FirebaseAuth.instance.signOut();
    showAppSnackBar(context, SnackbertMessages.randomLogoutMessage);
  }

  @override
  Widget build(BuildContext context) {
    // STYLING
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isSubmitting = ref.watch(mealSubmittingProvider);
    final isRecordingAudio = ref.watch(audioRecordingProvider);

    final isLocked = isSubmitting || isRecordingAudio;

    Widget activePage = const NewEntryScreen();
    var activePageTitle = "Neuer Eintrag";

    if (_selectedPageIndex == 1) {
      activePage = OverviewScreen();
      activePageTitle = "Deine Übersicht";
    }

    return PopScope(
      canPop: !isLocked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(activePageTitle),
          backgroundColor: colors.secondaryContainer,
          actions: [
            IconButton.filled(
              onPressed: isLocked ? null : _onTapLogOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: activePage,
        bottomNavigationBar: IgnorePointer(
          ignoring: isLocked,
          child: BottomNavigationBar(
            currentIndex: _selectedPageIndex,
            onTap: _selectPage,
            selectedFontSize: 16,
            selectedItemColor: const Color.fromARGB(183, 0, 0, 0),
            backgroundColor: colors.secondaryContainer,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: "Eintragen",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_rounded),
                label: "Übersicht",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

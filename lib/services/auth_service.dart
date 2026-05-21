// Not implemented currently, will get back to it later

import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool get isSignedIn => _isLoggedIn;

  bool _initializing = false;
  bool get isInitializing => _initializing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void initialize() {
    _initializing = false;
    notifyListeners();
  }

  Future<void> signIn() async {
    _errorMessage = null;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoggedIn = false;
    notifyListeners();
  }

  @override
  void dispose() {
    // will be of use again once firebase will be re-implemented
    super.dispose();
  }
}

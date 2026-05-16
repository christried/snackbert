import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initializing = true;
  bool get isInitializing => _initializing;

  bool get isSignedIn => _user != null;

  bool _initialized = false;
  bool _suppressAutoSignIn = false;

  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    final signIn = GoogleSignIn.instance;

    unawaited(
      signIn.initialize().then((_) {
        // Subscribe to the authentication event stream. Every sign-in and
        // sign-out — whether triggered by the app or the OS — comes through here.
        signIn.authenticationEvents.listen(_onAuthEvent).onError(_onAuthError);

        if (!_suppressAutoSignIn) {
          // Attempt a silent sign-in using a cached credential. No UI is shown.
          // If it succeeds the stream above emits a SignIn event automatically.
          signIn.attemptLightweightAuthentication();
        }

        _initializing = false;
        notifyListeners();
      }),
    );
  }

  Future<void> signIn() async {
    _errorMessage = null;
    notifyListeners();

    try {
      await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      _errorMessage = _describeException(e);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _suppressAutoSignIn = true;
    await GoogleSignIn.instance.signOut();
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    _errorMessage = null;

    _user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    notifyListeners();
  }

  void _onAuthError(Object error) {
    _user = null;
    _errorMessage = error is GoogleSignInException
        ? _describeException(error)
        : 'Unexpected error: $error';
    notifyListeners();
  }

  /// Converts a [GoogleSignInException] into a user-facing string.
  String _describeException(GoogleSignInException e) {
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Anmeldung abgebrochen.',
      GoogleSignInExceptionCode.providerConfigurationError =>
        'Google Sign-In ist nicht konfiguriert. Bitte die Einrichtung prüfen.',
      _ => 'Anmeldung fehlgeschlagen (${e.code}): ${e.description}',
    };
  }
}

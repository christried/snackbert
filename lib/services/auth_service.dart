import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  GoogleSignInAccount? _user;
  GoogleSignInAccount? get user => _user;

  User? _firebaseUser;
  StreamSubscription<User?>? _firebaseAuthSub;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _initializing = true;
  bool get isInitializing => _initializing;

  bool get isSignedIn => _firebaseUser != null;

  bool _initialized = false;
  bool _suppressAutoSignIn = false;

  void initialize() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    _firebaseUser = FirebaseAuth.instance.currentUser;
    _firebaseAuthSub ??= FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      _firebaseUser = user;
      notifyListeners();
    });

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

  // necessary to upload stuff to firebase (because i set it in Rules that way)
  Future<void> _signInToFirebase(GoogleSignInAccount user) async {
    try {
      final auth = user.authentication;
      if (auth.idToken == null) {
        throw StateError('Google-ID-Token fehlt.');
      }
      final credential = GoogleAuthProvider.credential(idToken: auth.idToken);

      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      _errorMessage = 'Firebase-Anmeldung fehlgeschlagen: ${e.code}';
      notifyListeners();
      await Future.wait([
        GoogleSignIn.instance.signOut(),
        FirebaseAuth.instance.signOut(),
      ]);
    } catch (e) {
      _errorMessage = 'Firebase-Anmeldung fehlgeschlagen: $e';
      notifyListeners();
      await Future.wait([
        GoogleSignIn.instance.signOut(),
        FirebaseAuth.instance.signOut(),
      ]);
    }
  }

  Future<void> signOut() async {
    _suppressAutoSignIn = true;
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      FirebaseAuth.instance.signOut(),
    ]);
  }

  void _onAuthEvent(GoogleSignInAuthenticationEvent event) {
    _errorMessage = null;

    _user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    if (event is GoogleSignInAuthenticationEventSignIn) {
      unawaited(_signInToFirebase(event.user));
    } else {
      unawaited(FirebaseAuth.instance.signOut());
    }

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

  @override
  void dispose() {
    _firebaseAuthSub?.cancel();
    super.dispose();
  }
}

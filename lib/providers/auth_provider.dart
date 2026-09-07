import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/firebase_error_mapper.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  loadingProfile,
  needsProfileCompletion,
  authenticated,
  error,
}

class GooglePrefillData {
  final String email;
  final String? displayName;
  final String? photoUrl;

  GooglePrefillData({
    required this.email,
    this.displayName,
    this.photoUrl,
  });
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUser?>? _userSubscription;

  AuthStatus _status = AuthStatus.initial;
  AppUser? _currentUser;
  GooglePrefillData? _googlePrefillData;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get currentUser => _currentUser;
  GooglePrefillData? get googlePrefillData => _googlePrefillData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.authenticating || _status == AuthStatus.loadingProfile;

  AuthProvider() {
    _initAuthListener();
  }

  void _initAuthListener() {
    _authSubscription = _authService.authStateChanges.listen((User? firebaseUser) async {
      debugPrint('>>> [AuthProvider] authStateChanged: ${firebaseUser != null ? "uid=${firebaseUser.uid}, email=${firebaseUser.email}" : "null"}');
      if (firebaseUser == null) {
        _userSubscription?.cancel();
        _currentUser = null;
        _googlePrefillData = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      } else {
        if (_currentUser == null || _currentUser!.uid != firebaseUser.uid) {
          _status = AuthStatus.loadingProfile;
          notifyListeners();
        }
        await _loadFirestoreUser(firebaseUser.uid, firebaseUser);
      }
    });
  }

  Future<void> _loadFirestoreUser(String uid, User firebaseUser) async {
    try {
      _userSubscription?.cancel();
      _userSubscription = _firestoreService.streamUserProfile(uid).listen((AppUser? user) {
        debugPrint('>>> [AuthProvider] streamUserProfile update: ${user != null ? "user=${user.fullName} role=${user.role}" : "null"}');
        if (user != null) {
          _currentUser = user;
          _status = AuthStatus.authenticated;
          notifyListeners();
        } else if (_currentUser == null) {
          // Document does not exist in Firestore yet and no local user set
          _googlePrefillData = GooglePrefillData(
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName,
            photoUrl: firebaseUser.photoURL,
          );
          _status = AuthStatus.needsProfileCompletion;
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('>>> [AuthProvider] streamUserProfile error: $err');
        _errorMessage = FirebaseErrorMapper.getMessage(err);
        _status = AuthStatus.error;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('>>> [AuthProvider] _loadFirestoreUser catch: $e');
      _errorMessage = FirebaseErrorMapper.getMessage(e);
      _status = AuthStatus.error;
      notifyListeners();
    }
  }

  // Email/Password Login
  Future<bool> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final normalizedEmail = email.trim().toLowerCase();
      debugPrint('>>> [AuthProvider] 1. signInWithEmailAndPassword starting for: $normalizedEmail');

      final creds = await _authService.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final firebaseUser = creds.user;
      debugPrint('>>> [AuthProvider] 2. Firebase Auth authenticated: uid=${firebaseUser?.uid}, email=${firebaseUser?.email}');

      if (firebaseUser != null) {
        try {
          debugPrint('>>> [AuthProvider] 3. Fetching Firestore profile for uid=${firebaseUser.uid}...');
          final profile = await _firestoreService
              .getUserProfile(firebaseUser.uid)
              .timeout(const Duration(seconds: 4));

          if (profile != null) {
            debugPrint('>>> [AuthProvider] 4. Profile found: ${profile.fullName} (role: ${profile.role})');
            _currentUser = profile;
            _status = AuthStatus.authenticated;
            notifyListeners();
          } else {
            debugPrint('>>> [AuthProvider] 4. No Firestore document for ${firebaseUser.uid}. Auto-creating default Customer profile...');
            final defaultName = (firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty)
                ? firebaseUser.displayName!
                : normalizedEmail.split('@').first;

            final newCustomer = AppUser(
              uid: firebaseUser.uid,
              fullName: defaultName,
              email: normalizedEmail,
              phone: '',
              location: 'Coimbatore, Tamil Nadu',
              role: AppConstants.roleCustomer,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            try {
              await _firestoreService.createUserProfile(newCustomer);
              debugPrint('>>> [AuthProvider] 5. Default Customer profile created and saved to Firestore!');
              _currentUser = newCustomer;
              _status = AuthStatus.authenticated;
              notifyListeners();
            } catch (createErr) {
              debugPrint('>>> [AuthProvider] Auto-create profile failed: $createErr');
              _googlePrefillData = GooglePrefillData(
                email: firebaseUser.email ?? normalizedEmail,
                displayName: defaultName,
              );
              _status = AuthStatus.needsProfileCompletion;
              notifyListeners();
            }
          }
        } catch (fetchErr, stack) {
          debugPrint('>>> [AuthProvider] Profile fetch error/timeout: $fetchErr\n$stack');
          if (_currentUser == null) {
            _status = AuthStatus.loadingProfile;
            notifyListeners();
          }
        }
        _loadFirestoreUser(firebaseUser.uid, firebaseUser);
      }
      return true;
    } catch (e, stack) {
      debugPrint('>>> [AuthProvider] loginWithEmailAndPassword FAILED: $e\n$stack');
      _errorMessage = FirebaseErrorMapper.getMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Register Customer or Worker
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String location,
    required String role, // customer or worker ONLY
    String? password, // null if registering after Google Sign-In
    String? serviceCategory,
    String? experience,
    String? certifications,
    List<String>? skills,
  }) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      // Enforce strict security rule: Only customer and worker allowed
      if (role != AppConstants.roleCustomer && role != AppConstants.roleWorker) {
        throw Exception('Registration is restricted to Customer and Worker roles only.');
      }

      User? firebaseUser = _authService.currentUser;
      final normalizedEmail = email.trim().toLowerCase();

      // If email/password registration, create Firebase Auth account first
      if (password != null && password.isNotEmpty) {
        final creds = await _authService.registerWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        firebaseUser = creds.user;
      }

      if (firebaseUser == null) {
        throw Exception('User authentication failed. Please try again.');
      }

      final now = DateTime.now();
      final appUser = AppUser(
        uid: firebaseUser.uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        location: location.trim(),
        profileImageUrl: _googlePrefillData?.photoUrl,
        role: role,
        createdAt: now,
        updatedAt: now,
        serviceCategory: serviceCategory?.trim(),
        skills: skills ?? (serviceCategory != null ? [serviceCategory] : []),
        experience: experience?.trim(),
        certifications: certifications?.trim(),
        verificationStatus: role == AppConstants.roleWorker ? AppConstants.statusPending : null,
      );

      // Create Firestore User Document
      await _firestoreService.createUserProfile(appUser);

      _currentUser = appUser;
      _googlePrefillData = null;
      _status = AuthStatus.authenticated;
      notifyListeners();

      _loadFirestoreUser(firebaseUser.uid, firebaseUser);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorMapper.getMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Continue with Google
  Future<bool> signInWithGoogle() async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithGoogle();
      if (userCredential == null) {
        // User cancelled sign in
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        try {
          final profile = await _firestoreService
              .getUserProfile(firebaseUser.uid)
              .timeout(const Duration(seconds: 4));
          if (profile != null) {
            _currentUser = profile;
            _status = AuthStatus.authenticated;
            notifyListeners();
          } else {
            _googlePrefillData = GooglePrefillData(
              email: firebaseUser.email ?? '',
              displayName: firebaseUser.displayName,
              photoUrl: firebaseUser.photoURL,
            );
            _status = AuthStatus.needsProfileCompletion;
            notifyListeners();
          }
        } catch (_) {
          _status = AuthStatus.loadingProfile;
          notifyListeners();
        }
        _loadFirestoreUser(firebaseUser.uid, firebaseUser);
      }
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorMapper.getMessage(e);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  // Send Password Reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _errorMessage = null;
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = FirebaseErrorMapper.getMessage(e);
      notifyListeners();
      return false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    _status = AuthStatus.authenticating;
    notifyListeners();
    _userSubscription?.cancel();
    await _authService.signOut();
    _currentUser = null;
    _googlePrefillData = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Refresh Current User Profile from Firestore
  Future<void> refreshCurrentUser() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      final user = await _firestoreService.getUserProfile(firebaseUser.uid);
      if (user != null) {
        _currentUser = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }
}

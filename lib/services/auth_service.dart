import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' show pow;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const Duration _tokenRefreshInterval = Duration(hours: 1);
  static const int _maxSignInAttempts = 3;
  
  int _signInAttempts = 0;
  DateTime? _lastSignInAttempt;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Connexion avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    // Validation des entrées
    if (email.isEmpty || password.isEmpty) {
      throw ArgumentError('Email et mot de passe ne peuvent pas être vides');
    }

    if (!_isValidEmail(email)) {
      throw ArgumentError('Format d\'email invalide');
    }

    // Vérification du nombre de tentatives
    if (_shouldBlockSignIn()) {
      final remainingTime = _getRemainingBlockTime();
      throw Exception('Trop de tentatives. Réessayez dans ${remainingTime.inMinutes} minutes');
    }

    try {
      _signInAttempts++;
      _lastSignInAttempt = DateTime.now();

      debugPrint('🔐 Tentative de connexion pour: $email');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _resetSignInAttempts();
        debugPrint('✅ Connexion réussie pour: $email');
        
        // Programmer le rafraîchissement du token
        _scheduleTokenRefresh(userCredential.user!);
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      debugPrint('❌ Erreur inattendue lors de la connexion: $e');
      throw Exception('Une erreur est survenue lors de la connexion');
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Déconnexion en cours...');
      await _auth.signOut();
      debugPrint('✅ Déconnexion réussie');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }

  // Vérifier si l'utilisateur est un membre du personnel
  Future<bool> isStaffMember() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('ℹ️ Aucun utilisateur connecté');
      return false;
    }

    try {
      debugPrint('🔍 Vérification des droits pour: ${user.email}');
      final idTokenResult = await user.getIdTokenResult(true); // Force refresh
      final isStaff = idTokenResult.claims?['isStaff'] == true;
      
      debugPrint(isStaff 
        ? '✅ Utilisateur confirmé comme membre du personnel'
        : '⚠️ Utilisateur non membre du personnel');
      
      return isStaff;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du rôle: $e');
      return false;
    }
  }

  // Méthodes privées
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _shouldBlockSignIn() {
    if (_signInAttempts >= _maxSignInAttempts && _lastSignInAttempt != null) {
      final blockDuration = Duration(minutes: pow(2, _signInAttempts - _maxSignInAttempts).toInt());
      return DateTime.now().difference(_lastSignInAttempt!) < blockDuration;
    }
    return false;
  }

  Duration _getRemainingBlockTime() {
    if (_lastSignInAttempt == null) return Duration.zero;
    
    final blockDuration = Duration(minutes: pow(2, _signInAttempts - _maxSignInAttempts).toInt());
    final elapsed = DateTime.now().difference(_lastSignInAttempt!);
    return blockDuration - elapsed;
  }

  void _resetSignInAttempts() {
    _signInAttempts = 0;
    _lastSignInAttempt = null;
  }

  Future<void> _scheduleTokenRefresh(User user) async {
    try {
      await Future.delayed(_tokenRefreshInterval);
      if (_auth.currentUser?.uid == user.uid) {
        await user.getIdToken(true);
        debugPrint('🔄 Token rafraîchi pour: ${user.email}');
        _scheduleTokenRefresh(user); // Planifier le prochain rafraîchissement
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors du rafraîchissement du token: $e');
    }
  }

  Exception _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Aucun utilisateur trouvé avec cet email');
      case 'wrong-password':
        return Exception('Mot de passe incorrect');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé');
      case 'too-many-requests':
        return Exception('Trop de tentatives. Veuillez réessayer plus tard');
      case 'invalid-email':
        return Exception('Format d\'email invalide');
      default:
        return Exception('Erreur d\'authentification: ${e.message}');
    }
  }
}
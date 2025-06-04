import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtenir l'utilisateur actuel
  User? get currentUser => _auth.currentUser;

  // Stream pour suivre l'état de l'authentification
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Connexion avec email et mot de passe
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Erreur de connexion: $e');
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Vérifier si l'utilisateur est un membre du personnel
  Future<bool> isStaffMember() async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final idTokenResult = await user.getIdTokenResult();
      return idTokenResult.claims?['isStaff'] == true;
    } catch (e) {
      print('Erreur lors de la vérification du rôle: $e');
      return false;
    }
  }
}
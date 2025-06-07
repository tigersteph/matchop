import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Enum pour les types de SnackBar
enum SnackBarType {
  success(Icons.check_circle, Colors.green),
  error(Icons.error, Colors.red),
  info(Icons.info, Colors.blue);

  const SnackBarType(this.icon, this.color);
  
  final IconData icon;
  final Color color;
}

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _errorMessage;
  String _searchQuery = '';

  // Filtres et tri
  String _sortField = 'createdAt';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer l\'email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }
    return null;
  }

  Future<void> _createStaffAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Vérifier si l'email existe déjà (méthode plus sécurisée)
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
          throw 'Un compte existe déjà avec cet email';
        }
        rethrow;
      }
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Ajouter les informations du personnel dans Firestore
      await FirebaseFirestore.instance
          .collection('staff')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.toLowerCase().trim(),
        'role': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
        'active': true,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // Afficher un message de succès
      _showSnackBar(
        'Compte du personnel créé avec succès',
        type: SnackBarType.success,
      );

      // Réinitialiser le formulaire
      _resetForm();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la création du compte: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide';
      case 'operation-not-allowed':
        return 'La création de compte est désactivée';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      default:
        return 'Une erreur est survenue: $code';
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    setState(() {
      _errorMessage = null;
      _isPasswordVisible = false;
    });
  }

  Future<void> _deleteStaffMember(String docId, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer $staffName de l\'équipe ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('staff')
          .doc(docId)
          .delete();
      
      _showSnackBar(
        'Membre du personnel supprimé',
        type: SnackBarType.info,
      );
    } catch (e) {
      _showSnackBar(
        'Erreur lors de la suppression: $e',
        type: SnackBarType.error,
      );
    }
  }

  void _showSnackBar(String message, {required SnackBarType type}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              type.icon,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: type.color,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion du Personnel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Aide',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Aide - Gestion du Personnel'),
                  content: SingleChildScrollView(
                    child: Text(
                      '• Pour ajouter un membre du personnel, remplissez le formulaire en haut\n'
                      '• Le mot de passe doit contenir au moins 8 caractères, une majuscule et un chiffre\n'
                      '• Vous pouvez rechercher un membre par son nom ou email\n'
                      '• Utilisez les filtres pour trier la liste\n'
                      '• Cliquez sur l\'icône de suppression pour retirer un membre',
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez entrer le nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      obscureText: !_isPasswordVisible,
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error.withValues(alpha: 26), // 26 = 0.1 * 255
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _errorMessage = null;
                                });
                              },
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createStaffAccount,
                      icon: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Créer un compte personnel'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  const Text(
                    'Liste du personnel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _sortField,
                    items: const [
                      DropdownMenuItem(
                        value: 'createdAt',
                        child: Text('Trier par date'),
                      ),
                      DropdownMenuItem(
                        value: 'name',
                        child: Text('Trier par nom'),
                      ),
                      DropdownMenuItem(
                        value: 'email',
                        child: Text('Trier par email'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortField = value;
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un membre...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400, // Hauteur fixe pour la liste
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('staff')
                      .orderBy(_sortField, descending: !_sortAscending)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final allStaff = snapshot.data!.docs;
                    
                    // Filtrer les résultats selon la recherche
                    final filteredStaff = allStaff.where((doc) {
                      if (_searchQuery.isEmpty) return true;
                      
                      final data = doc.data() as Map<String, dynamic>;
                      final name = (data['name'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      
                      return name.contains(_searchQuery) ||
                             email.contains(_searchQuery);
                    }).toList();

                    if (filteredStaff.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun membre du personnel'
                                  : 'Aucun résultat pour "$_searchQuery"',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredStaff.length,
                      itemBuilder: (context, index) {
                        final doc = filteredStaff[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Sans nom';
                        final email = data['email'] ?? 'Sans email';
                        final createdAt = data['createdAt'] as Timestamp?;

                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                name.toString().substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(email),
                                if (createdAt != null)
                                  Text(
                                    'Ajouté le ${_formatDate(createdAt.toDate())}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () => _deleteStaffMember(doc.id, name),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }
} 
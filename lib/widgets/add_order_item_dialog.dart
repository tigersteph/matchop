import 'package:flutter/material.dart';
import '../models/order.dart';

class AddOrderItemDialog extends StatefulWidget {
  const AddOrderItemDialog({Key? key}) : super(key: key);

  @override
  State<AddOrderItemDialog> createState() => _AddOrderItemDialogState();
}

class _AddOrderItemDialogState extends State<AddOrderItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _specialInstructionsController = TextEditingController();
  MenuCategory _selectedCategory = MenuCategory.plat;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  String _getCategoryLabel(MenuCategory category) {
    switch (category) {
      case MenuCategory.entree:
        return 'Entrée';
      case MenuCategory.plat:
        return 'Plat';
      case MenuCategory.dessert:
        return 'Dessert';
      case MenuCategory.boisson:
        return 'Boisson';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un article'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MenuCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: MenuCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(_getCategoryLabel(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'article',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une quantité';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity < 1) {
                    return 'Veuillez entrer un nombre valide (min: 1)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialInstructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions spéciales (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final item = OrderItem(
                menuItemId: DateTime.now().toString(),
                name: _nameController.text,
                price: double.parse(_priceController.text),
                quantity: int.parse(_quantityController.text),
                specialInstructions: _specialInstructionsController.text.isEmpty
                    ? null
                    : _specialInstructionsController.text,
                category: _selectedCategory,
              );
              Navigator.of(context).pop(item);
            }
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
} 
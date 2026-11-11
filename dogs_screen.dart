import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class Dog {
  final String name;
  final String breed;
  final int age;
  final Uint8List? imageBytes;

  Dog({
    required this.name,
    required this.breed,
    required this.age,
    this.imageBytes,
  });

  Dog copyWith({String? name, String? breed, int? age, Uint8List? imageBytes}) {
    return Dog(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      imageBytes: imageBytes ?? this.imageBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
    };
  }

  factory Dog.fromJson(Map<String, dynamic> json) {
    Uint8List? bytes;
    if (json['imageBytes'] != null) {
      bytes = base64Decode(json['imageBytes'] as String);
    }
    return Dog(
      name: json['name'] as String,
      breed: json['breed'] as String,
      age: json['age'] as int,
      imageBytes: bytes,
    );
  }
}

class DogsScreen extends StatelessWidget {
  final List<Dog> dogs;
  final void Function(Dog) onAdd;
  final void Function(int) onDelete;
  final void Function(int, Dog) onUpdate;

  const DogsScreen({
    super.key,
    required this.dogs,
    required this.onAdd,
    required this.onDelete,
    required this.onUpdate,
  });

  Future<Uint8List?> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return null;
    return await picked.readAsBytes();
  }

  void _showDogDialog(BuildContext context, {Dog? existing, int? index}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final breedController = TextEditingController(text: existing?.breed ?? '');
    final ageController =
        TextEditingController(text: existing?.age.toString() ?? '');
    Uint8List? imageBytes = existing?.imageBytes;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(existing == null ? 'Add Dog' : 'Edit Dog'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final bytes = await _pickImage();
                        if (bytes != null) {
                          setDialogState(() => imageBytes = bytes);
                        }
                      },
                      child: CircleAvatar(
                        radius: 45,
                        backgroundColor: Colors.purple.shade100,
                        backgroundImage: imageBytes != null
                            ? MemoryImage(imageBytes!)
                            : null,
                        child: imageBytes == null
                            ? const Icon(Icons.add_a_photo,
                                color: Colors.purple, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Tap to add photo',
                        style:
                            TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: breedController,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white),
                  child: const Text('Save'),
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        breedController.text.trim().isEmpty ||
                        ageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    final age = int.tryParse(ageController.text);
                    if (age == null || age < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid age.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    final dog = Dog(
                      name: nameController.text.trim(),
                      breed: breedController.text.trim(),
                      age: age,
                      imageBytes: imageBytes,
                    );
                    if (existing == null) {
                      onAdd(dog);
                    } else {
                      onUpdate(index!, dog);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: dogs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: Colors.purple.shade200),
                  const SizedBox(height: 16),
                  const Text(
                    'No dogs added yet.\nTap + to add your first dog.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                final dog = dogs[index];
                return Dismissible(
                  key: ValueKey(dog.name + index.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDelete(index),
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.purple.shade100,
                        backgroundImage: dog.imageBytes != null
                            ? MemoryImage(dog.imageBytes!)
                            : null,
                        child: dog.imageBytes == null
                            ? const Icon(Icons.pets, color: Colors.purple)
                            : null,
                      ),
                      title: Text(
                        dog.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text(
                        '${dog.breed} • ${dog.age} years old',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.purple),
                        onPressed: () =>
                            _showDogDialog(context, existing: dog, index: index),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDogDialog(context),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'dogs_screen.dart';
import 'walks_screen.dart';

void main() {
  runApp(const PawPal());
}

class PawPal extends StatelessWidget {
  const PawPal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PawPal',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFF8F0FF),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<Dog> _dogs = [];
  final List<Walk> _walks = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final dogsJson = prefs.getString('pawpal_dogs');
      if (dogsJson != null && dogsJson.isNotEmpty) {
        final List decoded = jsonDecode(dogsJson) as List;
        _dogs.clear();
        for (final d in decoded) {
          _dogs.add(Dog.fromJson(d as Map<String, dynamic>));
        }
      }

      final walksJson = prefs.getString('pawpal_walks');
      if (walksJson != null && walksJson.isNotEmpty) {
        final List decoded = jsonDecode(walksJson) as List;
        _walks.clear();
        for (final w in decoded) {
          _walks.add(Walk.fromJson(w as Map<String, dynamic>));
        }
      }
    } catch (_) {
      // start with empty lists if loading fails
    }

    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dogsJson = jsonEncode(_dogs.map((d) => d.toJson()).toList());
    final walksJson = jsonEncode(_walks.map((w) => w.toJson()).toList());
    await prefs.setString('pawpal_dogs', dogsJson);
    await prefs.setString('pawpal_walks', walksJson);
  }

  void _addDog(Dog dog) {
    setState(() => _dogs.add(dog));
    _saveData();
  }

  void _deleteDog(int index) {
    setState(() => _dogs.removeAt(index));
    _saveData();
  }

  void _updateDog(int index, Dog updated) {
    setState(() => _dogs[index] = updated);
    _saveData();
  }

  void _addWalk(Walk walk) {
    setState(() => _walks.insert(0, walk));
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F0FF),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, size: 56, color: Colors.purple),
              SizedBox(height: 16),
              CircularProgressIndicator(color: Colors.purple),
            ],
          ),
        ),
      );
    }

    final List<Widget> pages = [
      HomeScreen(dogs: _dogs, walks: _walks),
      DogsScreen(
        dogs: _dogs,
        onAdd: _addDog,
        onDelete: _deleteDog,
        onUpdate: _updateDog,
      ),
      WalksScreen(dogs: _dogs, walks: _walks, onWalkAdded: _addWalk),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PawPal 🐾'),
        centerTitle: true,
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.purple,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets), label: 'My Dogs'),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk), label: 'Walks'),
        ],
      ),
    );
  }
}

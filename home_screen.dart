import 'package:flutter/material.dart';
import 'dogs_screen.dart';
import 'walks_screen.dart';

class HomeScreen extends StatelessWidget {
  final List<Dog> dogs;
  final List<Walk> walks;

  const HomeScreen({super.key, required this.dogs, required this.walks});

  // Total minutes walked today across all dogs
  int _todayMinutes() {
    final now = DateTime.now();
    return walks
        .where((w) =>
            w.startTime.year == now.year &&
            w.startTime.month == now.month &&
            w.startTime.day == now.day)
        .fold(0, (sum, w) => sum + w.duration.inMinutes);
  }

  // Total minutes this week
  int _weekMinutes() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return walks
        .where((w) => w.startTime.isAfter(weekAgo))
        .fold(0, (sum, w) => sum + w.duration.inMinutes);
  }

  // Total distance this week
  double _weekDistance() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return walks
        .where((w) => w.startTime.isAfter(weekAgo))
        .fold(0.0, (sum, w) => sum + w.distanceMeters);
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    final todayMins = _todayMinutes();
    const goalMins = 60;
    final progress = (todayMins / goalMins).clamp(0.0, 1.0);
    final weekMins = _weekMinutes();
    final weekDist = _weekDistance();

    return SingleChildScrollView(
      child: Column(
        children: [
          // Purple gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B2FBE), Color(0xFFAB6FD8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              children: [
                const Icon(Icons.pets, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to PawPal!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your dog walking companion',
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily goal ring
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Today's Walk Goal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.purple.shade100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress >= 1.0 ? Colors.green : Colors.purple,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$todayMins',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                              const Text(
                                'of 60 mins',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    progress >= 1.0
                        ? '🎉 Goal reached! Great job!'
                        : '${goalMins - todayMins} minutes to go today',
                    style: TextStyle(
                      color: progress >= 1.0 ? Colors.green : Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Weekly summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This Week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatTile(
                        icon: Icons.timer,
                        label: 'Total Time',
                        value: '${weekMins}m',
                      ),
                      _StatTile(
                        icon: Icons.directions_walk,
                        label: 'Total Walks',
                        value: '${walks.where((w) {
                          final now = DateTime.now();
                          return w.startTime
                              .isAfter(now.subtract(const Duration(days: 7)));
                        }).length}',
                      ),
                      _StatTile(
                        icon: Icons.map,
                        label: 'Distance',
                        value: _formatDistance(weekDist),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dogs quick view
          if (dogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My Dogs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dogs.map((dog) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.purple.shade100,
                                backgroundImage: dog.imageBytes != null
                                    ? MemoryImage(dog.imageBytes!)
                                    : null,
                                child: dog.imageBytes == null
                                    ? const Icon(Icons.pets,
                                        color: Colors.purple)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                dog.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}

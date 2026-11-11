import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'dogs_screen.dart';

class Walk {
  final String dogName;
  final String walkerName;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final double distanceMeters;

  Walk({
    required this.dogName,
    required this.walkerName,
    required this.startTime,
    required this.endTime,
    required this.distanceMeters,
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'dogName': dogName,
      'walkerName': walkerName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'distanceMeters': distanceMeters,
    };
  }

  factory Walk.fromJson(Map<String, dynamic> json) {
    return Walk(
      dogName: json['dogName'] as String,
      walkerName: json['walkerName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      distanceMeters: (json['distanceMeters'] as num).toDouble(),
    );
  }
}

class WalksScreen extends StatefulWidget {
  final List<Dog> dogs;
  final List<Walk> walks;
  final void Function(Walk) onWalkAdded;

  const WalksScreen({
    super.key,
    required this.dogs,
    required this.walks,
    required this.onWalkAdded,
  });

  @override
  State<WalksScreen> createState() => _WalksScreenState();
}

class _WalksScreenState extends State<WalksScreen> {
  Dog? _selectedDog;
  final _walkerController = TextEditingController();
  DateTime? _currentWalkStart;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  StreamSubscription<Position>? _positionSubscription;
  double _distanceMeters = 0;
  Position? _lastPosition;
  bool _gpsAvailable = true;

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]}, $hour:$minute $period';
  }

  Color _walkColour(Duration d) {
    final mins = d.inMinutes;
    if (mins >= 60) return Colors.green;
    if (mins >= 30) return Colors.orange;
    return Colors.red;
  }

  Future<void> _startGPS() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() => _gpsAvailable = false);
        return;
      }
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        if (_lastPosition != null) {
          final delta = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          setState(() => _distanceMeters += delta);
        }
        _lastPosition = position;
      });
    } catch (_) {
      setState(() => _gpsAvailable = false);
    }
  }

  void _stopGPS() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastPosition = null;
  }

  Future<void> _startWalk() async {
    if (_selectedDog == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a dog before starting a walk.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _currentWalkStart = DateTime.now();
      _elapsed = Duration.zero;
      _distanceMeters = 0;
      _gpsAvailable = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed = DateTime.now().difference(_currentWalkStart!);
      });
    });

    await _startGPS();
  }

  void _stopWalk() {
    if (_currentWalkStart == null) return;

    final end = DateTime.now();
    _stopGPS();
    _timer?.cancel();

    final walk = Walk(
      dogName: _selectedDog!.name,
      walkerName: _walkerController.text.trim().isEmpty
          ? 'Unknown'
          : _walkerController.text.trim(),
      startTime: _currentWalkStart!,
      endTime: end,
      distanceMeters: _distanceMeters,
    );

    setState(() {
      _currentWalkStart = null;
      _elapsed = Duration.zero;
    });

    widget.onWalkAdded(walk);
    _showWalkSummary(walk);
  }

  void _showWalkSummary(Walk walk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Great walk! 🎉',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Dog', value: walk.dogName, icon: Icons.pets),
            _SummaryRow(
                label: 'Walker', value: walk.walkerName, icon: Icons.person),
            _SummaryRow(
                label: 'Duration',
                value: _formatDuration(walk.duration),
                icon: Icons.timer),
            _SummaryRow(
                label: 'Distance',
                value: _formatDistance(walk.distanceMeters),
                icon: Icons.map),
            const SizedBox(height: 16),
            walk.duration.inMinutes >= 60
                ? const Text('✅ Daily goal reached!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold))
                : Text(
                    '${60 - walk.duration.inMinutes} mins left to hit the daily goal',
                    style: const TextStyle(color: Colors.black54),
                  ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple, foregroundColor: Colors.white),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            onPressed: () {
              Navigator.of(context).pop();
              _shareWalk(walk);
            },
          ),
        ],
      ),
    );
  }

  void _shareWalk(Walk walk) {
    final box = context.findRenderObject() as RenderBox?;
    Share.share(
      '${walk.walkerName} just walked ${walk.dogName} ${_formatDistance(walk.distanceMeters)} in ${_formatDuration(walk.duration)}! 🐾🗺️ Tracked with PawPal. #PawPal #DogWalk',
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    _walkerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWalking = _currentWalkStart != null;
    final hasDogs = widget.dogs.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: hasDogs
              ? DropdownButtonFormField<Dog>(
                  value: _selectedDog,
                  decoration: const InputDecoration(
                    labelText: 'Select a dog',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.pets),
                  ),
                  items: widget.dogs.map((dog) {
                    return DropdownMenuItem(
                      value: dog,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.purple.shade100,
                            backgroundImage: dog.imageBytes != null
                                ? MemoryImage(dog.imageBytes!)
                                : null,
                            child: dog.imageBytes == null
                                ? const Icon(Icons.pets,
                                    size: 14, color: Colors.purple)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(dog.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: isWalking
                      ? null
                      : (dog) => setState(() => _selectedDog = dog),
                )
              : const Text(
                  'Add a dog in My Dogs first.',
                  style: TextStyle(color: Colors.black54),
                ),
        ),

        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _walkerController,
            enabled: !isWalking,
            decoration: const InputDecoration(
              labelText: "Walker's name",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          isWalking ? 'Walking ${_selectedDog!.name}...' : 'Not walking',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(_elapsed),
          style: const TextStyle(fontSize: 36),
        ),

        if (isWalking)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _gpsAvailable
                  ? '📍 ${_formatDistance(_distanceMeters)}'
                  : '📍 GPS unavailable',
              style: TextStyle(
                fontSize: 16,
                color: _gpsAvailable ? Colors.purple : Colors.grey,
              ),
            ),
          ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: isWalking ? null : _startWalk,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Walk'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white),
            ),
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: isWalking ? _stopWalk : null,
              icon: const Icon(Icons.stop),
              label: const Text('End Walk'),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const Divider(),

        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Walk history',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: widget.walks.isEmpty
              ? const Center(
                  child: Text(
                    'No walks logged yet.\nStart a walk to begin tracking.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.walks.length,
                  itemBuilder: (context, index) {
                    final walk = widget.walks[index];
                    final colour = _walkColour(walk.duration);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border(
                          left: BorderSide(color: colour, width: 5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.directions_walk, color: colour),
                        title: Text(
                          '${walk.dogName} — ${_formatDuration(walk.duration)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${_formatDistance(walk.distanceMeters)}  •  '
                          'By ${walk.walkerName}\n'
                          '${_formatDateTime(walk.startTime)} → ${_formatDateTime(walk.endTime)}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.share, color: Colors.purple),
                          onPressed: () => _shareWalk(walk),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple, size: 20),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

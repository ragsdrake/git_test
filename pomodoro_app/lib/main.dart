import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro Pets',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TimerScreen(),
    );
  }
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({Key? key}) : super(key: key);

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen>
    with SingleTickerProviderStateMixin {
  static const int pomodoroDuration = 25 * 60; // 25 minutes
  late int _remaining;
  Timer? _timer;
  int _completed = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _remaining = pomodoroDuration;
    _loadData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: pomodoroDuration),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completed = prefs.getInt('completed') ?? 0;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('completed', _completed);
  }

  void _startTimer() {
    if (_timer != null) return;
    _animationController.forward(from: 1 - _remaining / pomodoroDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _completed++;
          _saveData();
          _resetTimer();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    _animationController.stop();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = null;
    _animationController.reset();
    setState(() {
      _remaining = pomodoroDuration;
    });
  }

  String get _formattedTime {
    final minutes = (_remaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro Pets'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: PetPainter(progress: _animationController.value),
                  child: Center(
                    child: Text(
                      _formattedTime,
                      style: Theme.of(context).textTheme.headline2,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _startTimer,
                child: const Text('Start'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _pauseTimer,
                child: const Text('Pause'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _resetTimer,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Completed Pomodoros: $_completed'),
        ],
      ),
    );
  }
}

class PetPainter extends CustomPainter {
  final double progress;
  PetPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.orange;
    final double radius = 20 + (progress * 40);
    final Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant PetPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

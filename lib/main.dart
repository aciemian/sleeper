import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sleeper/sleep_service.dart';
import 'package:sleeper/sleep_state.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sleeper',
      home: HomePage(title: 'Sleeper'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SleepState _sleepState = SleepState();

  @override
  void initState() {
    super.initState();
    _sleepState.load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleeper'),
      ),
      body: StreamBuilder<SleepState>(
          stream: _sleepState.states.stream,
          builder: (context, snapshot) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  durationSlider(snapshot.hasData
                      ? snapshot.data!.sleepDuration.inMinutes
                      : _sleepState.sleepDuration.inMinutes),
                  activateButton(),
                ],
              ),
            );
          }),
    );
  }

  Widget durationSlider(int minutes) {
    const double durMin = 5;
    const double durMax = 60;
    double value = minutes.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Sleep Duration: $minutes minutes',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        Slider(
          value: max(min(value, durMax), durMin),
          min: durMin,
          max: durMax,
          divisions: (durMax - durMin) ~/ durMin,
          onChanged: (double value) {
            _sleepState.sleepDuration = Duration(minutes: value.round());
            _sleepState.save();
          },
        ),
      ],
    );
  }

  Widget activateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: ElevatedButton(
        child: const Text('Activate'),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.green),
          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 24)),
        ),
        onPressed: () {
          onActivate();
        },
      ),
    );
  }

  void onActivate() {
    SleepService.start(_sleepState);
  }
}

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
  final SleepState _sleepState = SleepState.load();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleeper'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            durationSlider(),
            activateButton(),
          ],
        ),
      ),
    );
  }

  Widget durationSlider() {
    const double durMin = 5;
    const double durMax = 60;
    double value = _sleepState.sleepDuration.inMinutes.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            'Sleep Duration: ${_sleepState.sleepDuration.inMinutes} minutes',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        Slider(
          value: max(min(value, durMax), durMin),
          min: durMin,
          max: durMax,
          divisions: (durMax - durMin) ~/ durMin,
          onChanged: (double value) {
            setState(() {
              _sleepState.sleepDuration = Duration(minutes: value.round());
              _sleepState.save();
            });
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
            setState(() {
              onActivate();
            });
          }),
    );
  }

  void onActivate() {
    SleepService.start(_sleepState);
  }
}

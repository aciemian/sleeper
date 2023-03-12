import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                  sleepDurationWidget(snapshot.hasData
                      ? snapshot.data!.sleepDuration.inMinutes
                      : _sleepState.sleepDuration.inMinutes),
                  keepAlivePeriodWidget(snapshot.hasData
                      ? snapshot.data!.keepAlivePeriod.inMinutes
                      : _sleepState.keepAlivePeriod.inMinutes),
                  buttons(),
                ],
              ),
            );
          }),
    );
  }

  Widget sleepDurationWidget(int minutes) {
    const double durMin = 5;
    const double durMax = 60;
    double value = minutes.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
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

  Widget keepAlivePeriodWidget(int minutes) {
    const double durMin = 0;
    const double durMax = 60;
    double value = minutes.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(
            'Keep Alive Period: $minutes minutes',
            style: const TextStyle(fontSize: 24),
          ),
        ),
        Slider(
          value: max(min(value, durMax), durMin),
          min: durMin,
          max: durMax,
          divisions: (durMax - durMin) ~/ 5,
          onChanged: (double value) {
            _sleepState.keepAlivePeriod = Duration(minutes: value.round());
            _sleepState.save();
          },
        ),
      ],
    );
  }

  Widget buttons() {
    return Row(
        children:[
          activateButton(),
          deactivateButton(),
        ]
    );
  }

  Widget activateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.green),
          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 24)),
        ),
        onPressed: () {
          onActivate();
        },
        child: const Text('Activate'),
      ),
    );
  }

  Widget deactivateButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(Colors.green),
          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 24)),
        ),
        onPressed: () {
          onDeactivate();
        },
        child: const Text('Deactivate'),
      ),
    );
  }

  void onActivate()  {
    SleepService.start(_sleepState);
    SystemNavigator.pop();
  }

  void onDeactivate()  {
    SleepService.stop();
    SystemNavigator.pop();
  }
}

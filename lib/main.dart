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
  bool isActive = false;

  @override
  void initState() {
    super.initState();
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            activateButton(),
            const SizedBox(
              height: 100,
            ),
            statusText(),
            const SizedBox(
              height: 100,
            ),
            durationSlider(),
          ],
        ),
      ),
    );
  }

  Widget activateButton() {
    String buttonText = '';
    Color buttonColor;

    if (isActive) {
      buttonText = 'Deactivate';
      buttonColor = Colors.red;
    } else {
      buttonText = 'Activate';
      buttonColor = Colors.green;
    }
    return Center(
      child: ElevatedButton(
          child: Text(buttonText),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(buttonColor),
            fixedSize: MaterialStateProperty.all(const Size(200, 100)),
            textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 30)),
          ),
          onPressed: () {
            setState(() {
              isActive ? onDeactivate() : onActivate();
            });
          }),
    );
  }

  Widget statusText() {
    const TextStyle style = TextStyle(fontSize: 30);
    String text = ' ';
    // if (isActive) {
      // text = _sleepState.isSleepTimerActive
      //     ? 'Music will sleep in ${formatDuration(_sleepState.sleepTimeRemaining)}'
      //     : 'Waiting for music to begin...';
    // }
    return Expanded(
      child: Text(
        text,
        style: style,
      ),
    );
  }

  Widget durationSlider() {
    const double durMin = 1;
    const double durMax = 30;
    double value = _sleepState.sleepDuration.inMinutes.toDouble();

    return Column(
      children: [
        Text(
          'Sleep Duration: ${_sleepState.sleepDuration.inMinutes} minutes',
          style: const TextStyle(fontSize: 20),
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

  void onActivate() {
    assert(!isActive);
    SleepService.start(_sleepState.sleepDuration, _sleepState.keepAlivePeriod);
  }

  void onDeactivate() {
    isActive = false;
    SleepService.stop();
  }

  String formatDuration(Duration d) {
    // Minutes:Seconds
    var seconds = d.inSeconds;
    var minutes = seconds ~/ 60;
    seconds = seconds.remainder(60);

    var minutesPadding = minutes < 10 ? "0" : "";
    var secondsPadding = seconds < 10 ? "0" : "";

    return '$minutesPadding$minutes:$secondsPadding$seconds';
  }
}

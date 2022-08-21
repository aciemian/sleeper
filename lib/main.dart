import 'dart:isolate';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:sleeper/sleep_state.dart';
import 'package:sleeper/sleeper_task.dart';
import 'package:sleeper/sleep_manager.dart';

void main() {
  runApp(const MyApp());
}

void startCallback() {
  FlutterForegroundTask.setTaskHandler(SleeperTaskHandler());
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
  ReceivePort? _receivePort;
  final SleepState _sleepState = SleepState.load();
  bool isActive = false;

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // You can get the previous ReceivePort without restarting the service.
      if (await FlutterForegroundTask.isRunningService) {
        final newReceivePort = await FlutterForegroundTask.receivePort;
        _registerReceivePort(newReceivePort);
      }
    });
  }

  @override
  void dispose() {
    onDeactivate();
    _closeReceivePort();
    super.dispose();
  }

  Future<bool> _startSleeperTask() async {
        bool reqResult;
    if (await FlutterForegroundTask.isRunningService) {
      reqResult = await FlutterForegroundTask.restartService();
    } else {
      reqResult = await FlutterForegroundTask.startService(
        notificationTitle: 'Sleep timer is running...',
        notificationText: '',
        callback: startCallback,
      );
    }

    ReceivePort? receivePort;
    if (reqResult) {
      receivePort = await FlutterForegroundTask.receivePort;
    }

    return _registerReceivePort(receivePort);
  }

  Future<bool> _stopSleeperTask() async {
    return FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? receivePort) {
    _closeReceivePort();

    if (receivePort == null) return false;

    _receivePort = receivePort;
    _receivePort!.listen(_listenOnReceivePort);
    /*
      _receivePort?.listen((message) {
        if (message is DateTime) {
          print('timestamp: ${message.toString()}');
        } else if (message is String) {
          if (message == 'onNotificationPressed') {
            Navigator.of(context).pushNamed('/resume-route');
          }
        }
      });
      */

    return true;
  }

  void _listenOnReceivePort(dynamic message) {
    assert(message is String);
    String event = message as String;
    switch (event) {
      case 'onStart':
        SleepManager.onStart(_sleepState);
        break;
      case 'onEvent':
        SleepManager.onTick(_sleepState);
        FlutterForegroundTask.updateService(notificationText: 'Time Remaining: ${formatDuration(_sleepState.sleepTimeRemaining)}');
        break;
      case 'onDestroy':
        _sleepState.cancel();
        break;
    }
    setState(() { });
    _sleepState.save();
  }

  void _closeReceivePort() {
    _receivePort?.close();
    _receivePort = null;
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
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
    if (isActive) {
      text = _sleepState.isSleepTimerActive
          ? 'Music will sleep in ${formatDuration(_sleepState.sleepTimeRemaining)}'
          : 'Waiting for music to begin...';
    }
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
    _startSleeperTask().then((started) => isActive = started);
  }

  void onDeactivate() {
    isActive = false;
    _stopSleeperTask();
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

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'Sleeper ID',
        channelName: 'Sleeper Name',
        channelDescription: 'Sleeper Description.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        enableVibration: false,
        iconData: null,
        buttons: [
          const NotificationButton(id: 'button', text: 'Button'),
        ],
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
      printDevLog: true,
    );
  }
}

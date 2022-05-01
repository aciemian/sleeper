import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_manager.dart';

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
  bool isActivated = false;
  DateTime? sleepTrigger;
  Timer? watchTimer;
  Duration watchPeriod = const Duration(seconds: 1);
  Duration sleepDuration = const Duration(minutes: 30);
  Duration keepAlivePeriod = const Duration(minutes: 5);
  DateTime lastKeepAlive = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadPrefs();
    watchTimer = Timer.periodic(watchPeriod, onWatchTimer);
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

    if (isActivated) {
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
              isActivated ? onDeactivate() : onActivate();
            });
          }),
    );
  }

  Widget statusText() {
    const TextStyle style = TextStyle(fontSize: 30);
    String text = ' ';
    if (isActivated) {
      text = isSleepTimerActive
          ? 'Music will sleep in ${formatDuration(sleepTimeRemaining)}'
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
    const int min = 5;
    const int max = 60;
    return Column(
      children: [
        Text(
          'Sleep Duration: ${sleepDuration.inMinutes} minutes',
          style: const TextStyle(fontSize: 20),
        ),
        Slider(
          value: sleepDuration.inMinutes.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: (max - min) ~/ min,
          onChanged: (double value) {
            setState(() {
              sleepDuration = Duration(minutes: value.round());
              savePrefs();
            });
          },
        ),
      ],
    );
  }

  void onActivate() {
    assert(!isActivated);
    isActivated = true;
    resetKeepAlive();
  }

  void onDeactivate() {
    isActivated = false;
    cancelSleepTimer();
  }

  void setSleepTimer() {
    sleepTrigger = DateTime.now().add(sleepDuration);
  }

  void cancelSleepTimer() {
    sleepTrigger = null;
  }

  bool get isSleepTimerActive {
    return (sleepTrigger != null);
  }

  Duration get sleepTimeRemaining {
    assert(isSleepTimerActive);
    assert(sleepTrigger != null);
    final now = DateTime.now();
    return now.isBefore(sleepTrigger!)
        ? sleepTrigger!.difference(now)
        : const Duration();
  }

  bool get isSleepTimeElapsed {
    assert(isSleepTimerActive);
    assert(sleepTrigger != null);
    return sleepTrigger!.isBefore(DateTime.now());
  }

  void resetKeepAlive() {
    lastKeepAlive = DateTime.now();
  }

  bool get isKeepAliveElapsed {
    return lastKeepAlive.add(keepAlivePeriod).isBefore(DateTime.now());
  }

  Future<void> onWatchTimerX(Timer t) async {
    if (!isActivated) return;
    bool isPlaying = await AndroidAudioManager.isAudioPlaying();
    if (isPlaying) {
      // Audio is currently playing
      if (isSleepTimerActive) {
        // Sleep timer is active
        if (isSleepTimeElapsed) {
          // Pause the audio and clear the sleep timer
          pausePlayer();
          cancelSleepTimer();
          // Start the keep alive process from
          resetKeepAlive();
        } else {
          // Keep waiting
        }
      } else {
        // Audio has started proper, restart the sleep timer
        setSleepTimer();
      }
    } else {
      // Audio is not playing, keep the player motivated if keep alive period has expired
      if (isKeepAliveElapsed) {
        motivatePlayer();
        resetKeepAlive();
      }
    }
    setState(() {});
  }

  Future<void> onWatchTimer(Timer t) async {
    if (!isActivated) return;
    bool isPlaying = await AndroidAudioManager.isAudioPlaying();
    // If timer has elapsed, pause the audio and clear the sleep timer
    if (isSleepTimerActive && isSleepTimeElapsed) {
      pausePlayer();
      isPlaying = false;
    }
    // Check status of player
    if (isPlaying) {
      // Audio is currently playing
      if (!isSleepTimerActive) {
        // Audio has started proper, restart the sleep timer
        setSleepTimer();
      }
    } else {
      // Audio is not playing
      // Reset the sleep timer
      cancelSleepTimer();
      // Keep the player motivated if keep alive period has expired
      if (isKeepAliveElapsed) {
        motivatePlayer();
        resetKeepAlive();
      }
    }
    setState(() {});
  }

  Future<void> pausePlayer() async {
    await AndroidAudioManager.simulateMediaKey(AndroidAudioManager.keyPause);
  }

  Future<void> motivatePlayer() async {
    // Simulating a media key press seems to be enough to keep player happy
    await AndroidAudioManager.simulateMediaKey(AndroidAudioManager.keyPause);
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

  void loadPrefs() {
    SharedPreferences.getInstance().then((prefs) {
      sleepDuration =
          Duration(minutes: prefs.getInt('sleep') ?? sleepDuration.inMinutes);
      setState(() {});
    });
  }

  void savePrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('sleep', sleepDuration.inMinutes);
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
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
  AudioSession? audioSession;
  Timer? sleepTimer;
  Timer? keepAliveTimer;
  Duration timerDuration = const Duration(seconds: 1);
  Duration sleepDuration = const Duration(minutes: 30);
  Duration keepAlivePeriod = const Duration(minutes:5);
  bool isActivated = false;

  @override
  void initState() {
    super.initState();
    AudioSession.instance.then((session) async {
      audioSession = session;
      // This line configures the app's audio session, indicating to the OS the
      // type of audio we intend to play. Using the "speech" recipe rather than
      // "music" since we are playing a podcast.
      audioSession?.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.soloAmbient,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      // Listen to audio interruptions and pause or duck as appropriate.
      handleInterruptions();
    });
    keepAliveTimer = Timer.periodic(keepAlivePeriod, onKeepAliveTimer);
  }

  void handleInterruptions() {
    audioSession?.interruptionEventStream.listen((event) {
      // print('interruption begin: ${event.begin}');
      // print('interruption type: ${event.type}');
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            break;
          case AudioInterruptionType.pause:
            break;
          case AudioInterruptionType.unknown:
            onInterrupt();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            break;
          case AudioInterruptionType.pause:
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });
  }

  void onInterrupt() {
    isAudioPlaying.then((playing) {
      if (playing) {
        setState(() {
          setSleepTimer();
        });
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleeper'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            activateButton(),
            const SizedBox(
              height: 160,
            ),
            statusText(),
            const SizedBox(
              height: 160,
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
    if ( isActivated ) {
      text = isTimerActive
          ? 'Music will sleep in ${formatDuration(sleepDuration - (timerDuration * sleepTimer!.tick))}'
          : 'Waiting for music to begin...';
    }
    return Expanded(
      child: Text( text, 
        style: style,
      ),
    );
  }


Widget durationSlider() {
  const int min = 5;
  const int max = 60;
  return Column(
    children: [
      Text( 'Sleep Duration: ${sleepDuration.inMinutes} minutes',
      style: const TextStyle(fontSize: 20),
      ),
      Slider( 
        value: sleepDuration.inMinutes.toDouble(),
        min: min.toDouble(),
        max: max.toDouble(),
        divisions: (max - min) ~/ min, 
        onChanged: (double value) {  setState(() {sleepDuration = Duration(minutes: value.round());});},),
    ],
  );
}

  void onActivate() {
    assert(sleepTimer == null);
    isActivated = true;
    isAudioPlaying.then((playing) {
      // print('Enabling - ' + (playing ? 'playing' : 'quiet'));
      setState( () {
        if (playing) {
          setSleepTimer();
        } else {
          setAudioFocus(true);
        }
      });
    });
  }

  void onDeactivate() {
    isActivated = false;
    // print('Disabling');
    cancelSleepTimer();
    setAudioFocus(false);
  }

  bool get isTimerActive {
    if (sleepTimer == null) return false;
    return sleepTimer!.isActive;
  }

  Future<bool> get isAudioPlaying {
    // try {
    //   return AVAudioSession().isOtherAudioPlaying;
    // } catch ( ex ) {}
    try {
      return AndroidAudioManager().isMusicActive();
    } catch (ex) {
      // Ignore
    }
    return Future.value(false);
  }

  void setSleepTimer() {
    // print('Setting timer');
    sleepTimer = Timer.periodic(timerDuration, onSleepTimer);
  }

  void cancelSleepTimer() {
    // print('Cancelling timer');
    sleepTimer?.cancel();
    sleepTimer = null;
  }

  void setAudioFocus(bool set) {
    // print('Setting audios focus - $set');
    try {
      audioSession?.setActive(set);
    } catch (e) {
      // print('_setAudioFocusException - ${e.toString()}');
    }
  }

  void onSleepTimer(Timer t) {
    // print('Timer activated');
    setState(() {
      if (sleepDuration < (timerDuration * t.tick)) {
        cancelSleepTimer();
        setAudioFocus(true);
      }
    });
  }

  Future<void> onKeepAliveTimer(Timer t) async {
    if (!isActivated) return;
    if (await isAudioPlaying) return;
    // Waiting for music to start, temporarily relinquish audio focus
    setAudioFocus(false);
    Future.delayed(const Duration(seconds: 1), () => setAudioFocus(true));
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

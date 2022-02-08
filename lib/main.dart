import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';

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
  AudioSession? audioSession;
  Timer? sleepTimer;
  Timer? keepAliveTimer;
  Duration timerDuration = const Duration(seconds: 1);
  Duration sleepDuration = const Duration(minutes: 30);
  Duration keepAlivePeriod = const Duration(minutes: 5);
  bool isActivated = false;

  @override
  void initState() {
    super.initState();
    AudioSession.instance.then((session) async {
      audioSession = session;
      audioSession?.configure(const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
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

  Future<void> onInterrupt() async {
    if (await isAudioPlaying) {
      setState(() => setSleepTimer());
    }
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
    if (isActivated) {
      text = isTimerActive
          ? 'Music will sleep in ${formatDuration(sleepDuration - (timerDuration * sleepTimer!.tick))}'
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
            });
          },
        ),
      ],
    );
  }

  Future<void> onActivate() async {
    assert(sleepTimer == null);
    isActivated = true;
    if (await isAudioPlaying) {
      // Audio is already active
      // Initiate the slepp timer
      setSleepTimer();
    } else {
      // Audio is not yet active
      // Claim audio focus so interrupt notification will be recieved when audio begins
      claimAudioFocus();
    }
  }

  Future<void> onDeactivate() async {
    isActivated = false;
    cancelSleepTimer();
    if (!await isAudioPlaying) {
      // If there is no active audio, make sure audio focus is releases
      releaseAudioFocusDeactivating();
    }
  }

  Future<bool> get isAudioPlaying {
    try {
      return AndroidAudioManager().isMusicActive();
    } catch (ex) {
      // Ignore
    }
    return Future.value(false);
  }

  void setSleepTimer() {
    sleepTimer = Timer.periodic(timerDuration, onSleepTimer);
  }

  void cancelSleepTimer() {
    sleepTimer?.cancel();
    sleepTimer = null;
  }

  bool get isTimerActive {
    return (sleepTimer != null);
  }

  Future<void> claimAudioFocus() async {
    await audioSession?.setActive(true,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient);
  }

  Future<void> releaseAudioFocus() async {
    // Releases the audio focus while activated
    // Since the focus was claimed transient, this typically results play resumption 
    await audioSession?.setActive(false, androidAudioFocusGainType:AndroidAudioFocusGainType.gainTransient);
  }

  Future<void> releaseAudioFocusDeactivating() async {
    // Releases the audio focus when deactivating
    // Since the focus was claimed transient, this typically results play resumption, 
    //    but the desired result is a focus release without triggering a play resumption. 
    // Mute the volume, so play resumption is not heard
    await AndroidAudioManager().adjustVolume(AndroidAudioAdjustment.mute,
        AndroidAudioVolumeFlags.removeSoundAndVibrate);
    // Release transient focus, play will resume
    await audioSession?.setActive(false,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient);
    await Future.delayed(const Duration(seconds: 1));
    // Reclaim permanant focus to cease play
    await audioSession?.setActive(true,
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain);
    await Future.delayed(const Duration(seconds: 2));
    // Unmute to return to previous volume setting
    await AndroidAudioManager().adjustVolume(AndroidAudioAdjustment.unmute,
        AndroidAudioVolumeFlags.removeSoundAndVibrate);
  }

  void onSleepTimer(Timer t) {
    // Wake up to check if sleep period has been reached and to update the countdown timer
    setState(() {
      if (sleepDuration < (timerDuration * t.tick)) {
        cancelSleepTimer();
        claimAudioFocus();
      }
    });
  }

  Future<void> onKeepAliveTimer(Timer t) async {  
    if (!isActivated) return;
    if (await isAudioPlaying) return;
    // The sleep timer is activated but is in the waiting state for music to be restarted.
    // This periodic event keeps the music player and this app active and
    //   keeps the music player ready to play when the headset play button is pressed.
    // Mute the audio 
    await AndroidAudioManager().adjustVolume(AndroidAudioAdjustment.mute,
        AndroidAudioVolumeFlags.removeSoundAndVibrate);
    // Release the transient audio focus to trigger the music to resume
    await releaseAudioFocus();
    await Future.delayed(const Duration(seconds: 1));
    // Reclaim the transient audio focus to stop the music 
    await claimAudioFocus();
    await Future.delayed(const Duration(seconds: 1));
    // Unmute to return to previous volume setting
    await AndroidAudioManager().adjustVolume(AndroidAudioAdjustment.unmute,
        AndroidAudioVolumeFlags.removeSoundAndVibrate);
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

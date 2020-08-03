/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sound_stream/sound_stream.dart';

enum Media {
  file,
  buffer,
  asset,
  stream,
  remoteExampleFile,
}
enum AudioState {
  isPlaying,
  isPaused,
  isStopped,
  isRecording,
  isRecordingPaused,
}

/// Boolean to specify if we want to test the Rentrance/Concurency feature.
/// If true, we start two instances of FlautoPlayer when the user hit the "Play" button.
/// If true, we start two instances of FlautoRecorder and one instance of FlautoPlayer when the user hit the Record button
final exampleAudioFilePath =
    "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
final albumArtPath =
    "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

void main() {
  runApp(MaterialApp(home: new MyApp()));
}

class MyApp2 extends StatefulWidget {
  @override
  _MyApp2State createState() => _MyApp2State();
}

class _MyApp2State extends State<MyApp2> {
  RecorderStream _recorder = RecorderStream();
  PlayerStream _player = PlayerStream();

  List<Uint8List> _micChunks = [];
  bool _isRecording = false;
  bool _isPlaying = false;

  StreamSubscription _recorderStatus;
  StreamSubscription _playerStatus;
  StreamSubscription _audioStream;

  @override
  void initState() {
    super.initState();
    initPlugin();
  }

  @override
  void dispose() {
    _recorderStatus?.cancel();
    _playerStatus?.cancel();
    _audioStream?.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlugin() async {
    _recorderStatus = _recorder.status.listen((status) {
      if (mounted)
        setState(() {
          _isRecording = status == SoundStreamStatus.Playing;
        });
    });

    _audioStream = _recorder.audioStream.listen((data) {
      if (_isPlaying) {
        _player.writeChunk(data);
      } else {
        debugPrint('data = ${data}');
        _micChunks.add(data);
      }
    });

    _playerStatus = _player.status.listen((status) {
      if (mounted)
        setState(() {
          _isPlaying = status == SoundStreamStatus.Playing;
        });
    });

//    await Future.wait([
    await _recorder.initialize(sampleRate: 44100, showLogs: true);
    await _player.initialize();
//    ]);
  }

  void _play() async {
    await _player.start();

    if (_micChunks.isNotEmpty) {
      for (var chunk in _micChunks) {
        await _player.writeChunk(chunk);
      }
      _micChunks.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              iconSize: 96.0,
              icon: Icon(_isRecording ? Icons.mic_off : Icons.mic),
              onPressed: _isRecording ? _recorder.stop : _recorder.start,
            ),
            IconButton(
              iconSize: 96.0,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: _isPlaying ? _player.stop : _play,
            ),
          ],
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterSoundRecorder flutterRecorder;
  final audioPlayer = AudioPlayer();
  BehaviorSubject<List<double>> peakLevelStream = BehaviorSubject();
  List<double> peakDuration = [];

  void setFlutterSound() async {
    flutterRecorder = new FlutterSoundRecorder();

    await flutterRecorder.openAudioSession(
        focus: AudioFocus.requestFocusTransientExclusive,
        category: SessionCategory.playAndRecord,
        mode: SessionMode.modeDefault,
        audioFlags: allowBlueTooth);
    defaultPath = await flutterRecorder.defaultPath(Codec.pcm16WAV);
    debugPrint('defaultPath = ${defaultPath}');
    await flutterRecorder.startRecorder(toFile: defaultPath);
    await flutterRecorder.stopRecorder();
    await flutterRecorder.setSubscriptionDuration(Duration(milliseconds: 30));
    flutterRecorder.onProgress.listen((event) {
      RecordingDisposition eventstream = event;
      peakDuration.insert(0, eventstream.decibels);
      if (peakDuration.length > 10) {
        peakDuration.removeLast();
      }
      peakLevelStream.add(peakDuration);
//      }
//      debugPrint('decibels = ${eventstream.decibels}');
//      debugPrint('duration = ${eventstream.duration}');
    });

    debugPrint('initfin');
  }

  String defaultPath = '';

  @override
  void initState() {
    setFlutterSound();
    super.initState();
  }

  bool isRecording = false;
  bool isSpeaking = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: RaisedButton(
                    color: isRecording == false ? Colors.white : Colors.red,
                    onPressed: () async {
                      File file = new File(defaultPath);
                      if (await file.exists()) {
                        await file.delete();
                      }

                      try {
                        flutterRecorder.startRecorder(
                            toFile: defaultPath,
                            sampleRate: 44100,
                            bitRate: 32000,
                            codec: Codec.pcm16WAV);
                      } catch (e) {
                        debugPrint('record error = ${e}');
                      }
                      setState(() {
                        isRecording = true;
                      });
                      await Future<dynamic>.delayed(Duration(seconds: 10));
                      debugPrint('finished recording');
                      setState(() {
                        isRecording = false;
                      });
                    },
                    child: Text('record'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      try {
                        flutterRecorder.stopRecorder();
                      } catch (e) {
                        debugPrint('record error = ${e}');
                      }

                      debugPrint('finished recording');
                      setState(() {
                        isRecording = false;
                      });
                    },
                    child: Text('stop'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: isSpeaking == false ? Colors.white : Colors.red,
                    onPressed: () async {
                      try {
                        await audioPlayer.setFilePath(defaultPath);
                        audioPlayer.play();
                        await Future<dynamic>.delayed(
                            Duration(milliseconds: 100));
                      } catch (e) {
                        debugPrint('audioPlayer.setFilePath error = ${e}');
                      }
                    },
                    child: Text('listen'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      audioPlayer.pause();
                    },
                    child: Text('stopPlayer'),
                  ),
                ),
                Center(
                  child: RaisedButton(
                    color: Colors.white,
                    onPressed: () async {
                      flutterRecorder.closeAudioSession();
                    },
                    child: Text('dispose'),
                  ),
                ),
                StreamBuilder<List<double>>(
                  initialData: [],
                  stream: peakLevelStream,
                  builder: (ctx, snap) {
                    List<double> list = snap.data;
                    if (list.isEmpty) {
                      debugPrint('is Empty');
                      return Container(
                        height: 1,
                        width: 1,
                      );
                    }
//                              return Container(
//                                height: 50,
//                                width: 1.0 / 0,
//                                child: LineChart(
//                                  pitchLineChart(list),
//                                  swapAnimationDuration:
//                                  Duration(milliseconds: 250),
//                                ),
//                              );
                    debugPrint('list = ${list}');
                    return Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        width: MediaQuery.of(context).size.width / 2,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: list
                                .map((e) => Container(
                                      color: Colors.red,
                                      height: e * 5,
                                      width: 5,
//                                    child: Center(child: Text('${list.last.toStringAsFixed(0)}DB')),
                                    ))
                                .toList()),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ));
  }
}

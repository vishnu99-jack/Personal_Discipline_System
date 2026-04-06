import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';

Future<void> playSound(Uint8List sound, AudioPlayer player) async {
  final file = File('${Directory.systemTemp.path}/temp_sound.mp3');
  await file.writeAsBytes(sound);

  await player.play(DeviceFileSource(file.path));
}
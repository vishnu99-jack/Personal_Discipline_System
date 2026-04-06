import 'dart:typed_data';
import 'dart:html' as html;
import 'package:audioplayers/audioplayers.dart';

Future<void> playSound(Uint8List sound, AudioPlayer player) async {
  final blob = html.Blob([sound]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  await player.play(UrlSource(url));
}
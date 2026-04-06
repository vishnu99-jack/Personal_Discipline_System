import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../services/audio_helper.dart';

class LeetcodeEditScreen extends StatefulWidget {
  const LeetcodeEditScreen({super.key});

  @override
  State<LeetcodeEditScreen> createState() => _LeetcodeEditScreenState();
}

class _LeetcodeEditScreenState extends State<LeetcodeEditScreen> {
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final TextEditingController targetController = TextEditingController();

  String startRingtone = "sounds/success.mp3";
  String successRingtone = "sounds/success.mp3";

  final AudioPlayer _audioPlayer = AudioPlayer();

  // 🔥 Available tones
  final List<String> tones = [
    "sounds/success.mp3",
  ];

  // 🔥 STORED AUDIO BYTES (PERSISTENT)
  Uint8List? startSoundBytes;
  Uint8List? successSoundBytes;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  void _loadConfig() {
    final box = Hive.box('leetcode_config');
    final data = box.get('config');

    if (data != null) {
      setState(() {
        if (data["startTime"] != null) {
          final parts = data["startTime"].split(":");
          startTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        if (data["endTime"] != null) {
          final parts = data["endTime"].split(":");
          endTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }

        targetController.text =
            (data["targetCount"] ?? "").toString();

        startRingtone =
            data["startRingtone"] ?? "sounds/success.mp3";

        successRingtone =
            data["successRingtone"] ?? "sounds/success.mp3";

        // 🔥 LOAD SAVED AUDIO BYTES
        if (data["startSoundBytes"] != null) {
          startSoundBytes =
              Uint8List.fromList(List<int>.from(data["startSoundBytes"]));
        }

        if (data["successSoundBytes"] != null) {
          successSoundBytes =
              Uint8List.fromList(List<int>.from(data["successSoundBytes"]));
        }
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startTime = picked;
        } else {
          endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return "Select Time";
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // 🔊 PLAY SOUND (ASSET OR BYTES)
  Future<void> _playSound({String? path, Uint8List? bytes}) async {
  try {
    await _audioPlayer.stop();

    if (bytes != null) {
     await playSound(bytes, _audioPlayer);

      
    } else if (path != null) {
      await _audioPlayer.play(AssetSource(path));
    }
  } catch (e) {
    debugPrint("Audio error: $e");
  }
}

  // 🔥 PICK + STORE AUDIO
  Future<void> _pickAudio(bool isStart) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;

      setState(() {
        if (isStart) {
          startSoundBytes = bytes;
          startRingtone = "custom";
        } else {
          successSoundBytes = bytes;
          successRingtone = "custom";
        }
      });

      await _playSound(bytes: bytes);
    }
  }

  Future<void> _saveConfig() async {
    final box = Hive.box('leetcode_config');

    await box.put('config', {
      "startTime": startTime != null
          ? "${startTime!.hour}:${startTime!.minute}"
          : null,
      "endTime": endTime != null
          ? "${endTime!.hour}:${endTime!.minute}"
          : null,
      "targetCount": int.tryParse(targetController.text) ?? 1,
      "startRingtone": startRingtone,
      "successRingtone": successRingtone,

      // 🔥 STORE AUDIO BYTES
      "startSoundBytes": startSoundBytes?.toList(),
      "successSoundBytes": successSoundBytes?.toList(),
    });

    Navigator.pop(context);
  }

  Widget _buildToneSelector({
    required String title,
    required String selectedTone,
    required Function(String) onSelect,
    Uint8List? customBytes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        Column(
          children: tones.map((tone) {
            final isSelected = tone == selectedTone;

            return ListTile(
              title: Text(tone.split('/').last),
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.blue : null,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => _playSound(path: tone),
              ),
              onTap: () {
                setState(() {
                  onSelect(tone);
                });
                _playSound(path: tone);
              },
            );
          }).toList(),
        ),

        // 🔥 CUSTOM AUDIO
        if (customBytes != null)
          ListTile(
            title: const Text("Custom Audio"),
            leading: const Icon(Icons.music_note),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playSound(bytes: customBytes),
            ),
          ),

        ElevatedButton.icon(
          onPressed: () => _pickAudio(title.contains("Start")),
          icon: const Icon(Icons.upload),
          label: const Text("Upload Custom Audio"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Leetcode Habit"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Set Your Habit Configuration",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ListTile(
              title: const Text("Start Time"),
              subtitle: Text(_formatTime(startTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _pickTime(true),
            ),

            ListTile(
              title: const Text("End Time"),
              subtitle: Text(_formatTime(endTime)),
              trailing: const Icon(Icons.access_time),
              onTap: () => _pickTime(false),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Problems per day",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            _buildToneSelector(
              title: "Start Ringtone",
              selectedTone: startRingtone,
              onSelect: (tone) => startRingtone = tone,
              customBytes: startSoundBytes,
            ),

            const SizedBox(height: 20),

            _buildToneSelector(
              title: "Success Ringtone",
              selectedTone: successRingtone,
              onSelect: (tone) => successRingtone = tone,
              customBytes: successSoundBytes,
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveConfig,
              child: const Text("Save Configuration"),
            ),
          ],
        ),
      ),
    );
  }
}
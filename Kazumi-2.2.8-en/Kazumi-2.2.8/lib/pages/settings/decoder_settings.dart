import 'package:flutter/material.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class DecoderSettings extends StatefulWidget {
  const DecoderSettings({super.key});

  @override
  State<DecoderSettings> createState() => _DecoderSettingsState();
}

class _DecoderSettingsState extends State<DecoderSettings> {
  late final ValueNotifier<String> decoder = ValueNotifier<String>(
    GStorage.getSetting<String>(SettingsKeys.hardwareDecoder),
  );

  @override
  void dispose() {
    decoder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SysAppBar(
        title: Text('Hardware Decoder'),
      ),
      body: SettingsList(
        sections: [
          SettingsRadioSection<String>(
            title: Text('Selecting an unsupported decoder will fall back to software decoding'),
            groupValue: decoder.value,
            onChanged: (String? value) {
              if (value != null) {
                GStorage.putSetting<String>(
                    SettingsKeys.hardwareDecoder, value);
                setState(() {
                  decoder.value = value;
                });
              }
            },
            tiles: hardwareDecodersList.entries
                .map((e) => SettingsTile<String>.radioTile(
                      title: Text(e.key),
                      description: Text(e.value),
                      radioValue: e.key,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

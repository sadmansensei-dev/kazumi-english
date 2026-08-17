import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/services/platform/secure_bookmark_service.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/utils/file_system.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:file_picker/file_picker.dart';

class DownloadSettingsPage extends StatefulWidget {
  const DownloadSettingsPage({super.key});

  @override
  State<DownloadSettingsPage> createState() => _DownloadSettingsPageState();
}

class _DownloadSettingsPageState extends State<DownloadSettingsPage> {
  late int parallelEpisodes;
  late int parallelSegments;
  late bool downloadDanmaku;
  String downloadDirectory = '';
  String defaultDownloadDirectory = '';
  bool isSelectingDirectory = false;

  @override
  void initState() {
    super.initState();
    parallelEpisodes =
        GStorage.getSetting(SettingsKeys.downloadParallelEpisodes);
    parallelSegments =
        GStorage.getSetting(SettingsKeys.downloadParallelSegments);
    downloadDanmaku = GStorage.getSetting(SettingsKeys.downloadDanmaku);
    downloadDirectory =
        GStorage.getSetting(SettingsKeys.downloadDirectory).trim();
    _loadDefaultDownloadDirectory();
  }

  bool get _canPickDirectory => supportsCustomDownloadDirectory;

  bool get _hasCustomDirectory =>
      _canPickDirectory && downloadDirectory.isNotEmpty;

  String get _effectiveDownloadDirectory =>
      _hasCustomDirectory ? downloadDirectory : defaultDownloadDirectory;

  Future<void> _loadDefaultDownloadDirectory() async {
    final directory = await getDefaultDownloadDirectory();
    if (!mounted) return;
    setState(() {
      defaultDownloadDirectory = directory;
    });
  }

  Future<void> _selectDownloadDirectory() async {
    if (!_canPickDirectory) {
      KazumiDialog.showToast(message: 'Manually selecting a directory is not supported on this platform');
      return;
    }
    if (isSelectingDirectory) return;

    setState(() => isSelectingDirectory = true);
    try {
      final effectiveDirectory = _effectiveDownloadDirectory;
      final initialDirectory = effectiveDirectory.isNotEmpty &&
              await Directory(effectiveDirectory).exists()
          ? effectiveDirectory
          : null;
      final selectedPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Choose Download Location',
        initialDirectory: initialDirectory,
      );
      if (selectedPath == null || selectedPath.isEmpty) return;

      await ensureDirectoryWritable(selectedPath);
      if (!await SecureBookmarkService.persist(selectedPath)) {
        KazumiDialog.showToast(message: 'Unable to obtain persistent access to this directory, please choose another');
        return;
      }
      await GStorage.putSetting(
        SettingsKeys.downloadDirectory,
        selectedPath,
      );
      if (mounted) {
        setState(() => downloadDirectory = selectedPath);
      }
      KazumiDialog.showToast(message: 'Download location updated, applies to new downloads only');
    } on FileSystemException catch (e) {
      KazumiDialog.showToast(message: 'Cannot write to this directory: ${e.message}');
    } catch (e) {
      KazumiDialog.showToast(message: 'Failed to choose download location: $e');
    } finally {
      if (mounted) {
        setState(() => isSelectingDirectory = false);
      }
    }
  }

  Future<void> _resetDownloadDirectory() async {
    await SecureBookmarkService.clear();
    await GStorage.putSetting(SettingsKeys.downloadDirectory, '');
    if (mounted) {
      setState(() => downloadDirectory = '');
    }
    KazumiDialog.showToast(message: 'Default download location restored, applies to new downloads only');
  }

  @override
  Widget build(BuildContext context) {
    return SettingsDetailScaffold(
      title: const Text('Download Settings'),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text('Concurrency Settings'),
            tiles: [
              SettingsSliderTile(
                leading: Icons.video_library_rounded,
                title: Text('Episode Concurrency'),
                description: Text('Number of episodes downloaded in parallel'),
                value: parallelEpisodes.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                valueLabel: '$parallelEpisodes episode(s)',
                onChanged: (value) {
                  setState(() => parallelEpisodes = value.toInt());
                  GStorage.putSetting(
                    SettingsKeys.downloadParallelEpisodes,
                    parallelEpisodes,
                  );
                },
              ),
              SettingsSliderTile(
                leading: Icons.call_split_rounded,
                title: Text('Segment Concurrency'),
                description: Text('Number of segments downloaded simultaneously per episode'),
                value: parallelSegments.toDouble(),
                min: 1,
                max: 10,
                divisions: 9,
                valueLabel: '$parallelSegments',
                onChanged: (value) {
                  setState(() => parallelSegments = value.toInt());
                  GStorage.putSetting(
                    SettingsKeys.downloadParallelSegments,
                    parallelSegments,
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text('Cache Settings'),
            tiles: [
              SettingsTile(
                leading: Icons.folder_rounded,
                title: Text('Download Location'),
                description: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _effectiveDownloadDirectory.isEmpty
                          ? 'Reading default location...'
                          : _effectiveDownloadDirectory,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _hasCustomDirectory
                          ? 'Currently using a custom download location; changes apply to new downloads only'
                          : 'Currently using the default download location; changes apply to new downloads only',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
                trailing: isSelectingDirectory
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _hasCustomDirectory
                        ? IconButton(
                            tooltip: 'Restore Default',
                            icon: const Icon(Icons.restore_rounded),
                            onPressed: _resetDownloadDirectory,
                          )
                        : null,
                onPressed: (_) => _selectDownloadDirectory(),
              ),
              SettingsTile.switchTile(
                leading: Icons.subtitles_rounded,
                onToggle: (value) {
                  setState(() => downloadDanmaku = value ?? !downloadDanmaku);
                  GStorage.putSetting(
                      SettingsKeys.downloadDanmaku, downloadDanmaku);
                },
                title: Text('Cache Danmaku'),
                description: Text(
                  'Cache danmaku data alongside video downloads',
                ),
                initialValue: downloadDanmaku,
              ),
            ],
          ),
          SettingsSection(
            title: Text('Description'),
            tiles: [
              SettingsTile(
                leading: Icons.info_outline_rounded,
                title: Text('About Concurrency Settings'),
                description: Text(
                  '• Episode concurrency: how many episodes to download at once\n'
                  '• Segment concurrency: how many video segments to download at once within an episode\n'
                  '• Higher concurrency can improve speed, but may be limited by the server\n'
                  '• Changes apply to downloads started after this',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

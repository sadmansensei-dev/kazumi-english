import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/pages/player/controller/player_aspect_ratio.dart';
import 'package:kazumi/services/network/metered_network_service.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/player/pip_utils.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/utils/device.dart';

class PlayerSettingsPage extends StatefulWidget {
  const PlayerSettingsPage({super.key});

  @override
  State<PlayerSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<PlayerSettingsPage> {
  static const double _minPlayerControllerLayerDisappearSeconds = 1;
  static const double _maxPlayerControllerLayerDisappearSeconds = 10;
  static const int _playerControllerLayerDisappearDivisions = 18;

  late double defaultPlaySpeed;
  late double defaultShortcutForwardPlaySpeed;
  late PlayerAspectRatio defaultAspectRatioMode;
  late bool hAenable;
  late bool androidEnableOpenSLES;
  late bool androidAutoEnterPIP;
  late bool lowMemoryMode;
  late bool playResume;
  late bool showPlayerError;
  late bool privateMode;
  late bool playerDebugMode;
  late bool playerDisableAnimations;
  late bool forceAdBlocker;
  late bool autoPlayNext;
  late bool backgroundPlayback;
  late bool brightnessVolumeGesture;
  late int playerButtonSkipTime;
  late int playerArrowKeySkipTime;
  late int playerLogLevel;
  late int playerControllerLayerDisappearTime;
  final MenuController playerAspectRatioMenuController = MenuController();
  final MenuController playerLogLevelMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    _loadSettingsFromStorage();
    MeteredNetworkService.listenable.addListener(_onMeteredNetworkChanged);
  }

  @override
  void dispose() {
    MeteredNetworkService.listenable.removeListener(_onMeteredNetworkChanged);
    super.dispose();
  }

  void _onMeteredNetworkChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _loadSettingsFromStorage() {
    defaultPlaySpeed =
        GStorage.getSetting<double>(SettingsKeys.defaultPlaySpeed);
    defaultShortcutForwardPlaySpeed = GStorage.getSetting<double>(
        SettingsKeys.defaultShortcutForwardPlaySpeed);
    defaultAspectRatioMode = PlayerAspectRatio.fromStorageValue(
      GStorage.getSetting<int>(SettingsKeys.defaultAspectRatioType),
    );
    hAenable = GStorage.getSetting<bool>(SettingsKeys.hAenable);
    androidEnableOpenSLES =
        GStorage.getSetting<bool>(SettingsKeys.androidEnableOpenSLES);
    androidAutoEnterPIP =
        GStorage.getSetting<bool>(SettingsKeys.androidAutoEnterPIP);
    lowMemoryMode = GStorage.getSetting<bool>(SettingsKeys.lowMemoryMode);
    playResume = GStorage.getSetting<bool>(SettingsKeys.playResume);
    privateMode = GStorage.getSetting<bool>(SettingsKeys.privateMode);
    showPlayerError = GStorage.getSetting<bool>(SettingsKeys.showPlayerError);
    playerDebugMode = GStorage.getSetting<bool>(SettingsKeys.playerDebugMode);
    autoPlayNext = GStorage.getSetting<bool>(SettingsKeys.autoPlayNext);
    backgroundPlayback =
        GStorage.getSetting<bool>(SettingsKeys.backgroundPlayback);
    playerDisableAnimations =
        GStorage.getSetting<bool>(SettingsKeys.playerDisableAnimations);
    forceAdBlocker = GStorage.getSetting<bool>(SettingsKeys.forceAdBlocker);
    playerLogLevel = GStorage.getSetting<int>(SettingsKeys.playerLogLevel);

    brightnessVolumeGesture =
        GStorage.getSetting<bool>(SettingsKeys.brightnessVolumeGesture);

    playerButtonSkipTime =
        GStorage.getSetting<int>(SettingsKeys.buttonSkipTime);
    playerArrowKeySkipTime =
        GStorage.getSetting<int>(SettingsKeys.arrowKeySkipTime);

    playerControllerLayerDisappearTime = GStorage.getSetting<int>(
        SettingsKeys.playerControllerLayerDisappearTime);
  }

  Future<void> resetPlayerSettings() async {
    final bool shouldReset = await KazumiDialog.show<bool>(
          builder: (context) => AlertDialog(
            title: const Text('Restore Default Playback Settings'),
            content: const Text('Playback settings, hardware decoder, video renderer, and super resolution settings will be reset to default.'),
            actions: [
              TextButton(
                onPressed: () => KazumiDialog.dismiss(popWith: false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => KazumiDialog.dismiss(popWith: true),
                child: Text('Restore Default'),
              ),
            ],
          ),
        ) ??
        false;
    if (!shouldReset) return;

    await GStorage.resetPlayerSettings();
    if (Platform.isAndroid) {
      await PipUtils.setAndroidAutoEnterPIPEnabled(false);
    }
    if (!mounted) return;
    setState(_loadSettingsFromStorage);
    KazumiDialog.showToast(message: 'Playback settings restored to default');
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  void updateDefaultPlaySpeed(double speed) {
    GStorage.putSetting<double>(SettingsKeys.defaultPlaySpeed, speed);
    setState(() {
      defaultPlaySpeed = speed;
    });
  }

  void updateDefaultShortcutForwardPlaySpeed(double speed) {
    GStorage.putSetting<double>(
        SettingsKeys.defaultShortcutForwardPlaySpeed, speed);
    setState(() {
      defaultShortcutForwardPlaySpeed = speed;
    });
  }

  void updatePlayerLogLevel(int level) {
    GStorage.putSetting<int>(SettingsKeys.playerLogLevel, level);
    setState(() {
      playerLogLevel = level;
    });
  }

  void updateDefaultAspectRatioMode(PlayerAspectRatio mode) {
    GStorage.putSetting<int>(
      SettingsKeys.defaultAspectRatioType,
      mode.storageValue,
    );
    setState(() {
      defaultAspectRatioMode = mode;
    });
  }

  Future<void> updateButtonSkipTime() async {
    final int? newButtonSkipTime = await _showSkipTimeChangeDialog(
        title: 'Top Button Fast-Forward Duration', initialValue: playerButtonSkipTime.toString());

    if (newButtonSkipTime != null &&
        newButtonSkipTime != playerButtonSkipTime) {
      GStorage.putSetting<int>(SettingsKeys.buttonSkipTime, newButtonSkipTime);
      setState(() {
        playerButtonSkipTime = newButtonSkipTime;
      });
    }
  }

  Future<int?> _showSkipTimeChangeDialog(
      {required String title, required String initialValue}) async {
    return KazumiDialog.show<int>(builder: (context) {
      String input = "";
      return AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return TextField(
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // 只允许输入数字
            ],
            decoration: InputDecoration(
              floatingLabelBehavior:
                  FloatingLabelBehavior.never, // 控制label的显示方式
              labelText: initialValue,
            ),
            onChanged: (value) {
              input = value;
            },
          );
        }),
        actions: <Widget>[
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () async {
              final int? newValue = int.tryParse(input);

              if (newValue == null) {
                KazumiDialog.showToast(message: 'Please enter a number');
                return;
              }

              if (newValue <= 0) {
                KazumiDialog.showToast(message: 'Please enter a number greater than 0');
                return;
              }
              // 以新设置的值弹出
              KazumiDialog.dismiss(popWith: newValue);
            },
            child: const Text('OK'),
          ),
        ],
      );
    });
  }

  double get playerControllerLayerDisappearSeconds =>
      (playerControllerLayerDisappearTime / Duration.millisecondsPerSecond)
          .clamp(_minPlayerControllerLayerDisappearSeconds,
              _maxPlayerControllerLayerDisappearSeconds)
          .toDouble();

  String formatPlayerControllerLayerDisappearSeconds(double seconds) {
    if (seconds == seconds.roundToDouble()) {
      return '${seconds.toInt()} sec';
    }
    return '${seconds.toStringAsFixed(1)} sec';
  }

  void updatePlayerControllerLayerDisappearSeconds(double seconds) {
    final int newDisappearTime =
        (seconds * Duration.millisecondsPerSecond).round();
    if (newDisappearTime == playerControllerLayerDisappearTime) {
      return;
    }
    GStorage.putSetting<int>(
        SettingsKeys.playerControllerLayerDisappearTime, newDisappearTime);
    setState(() {
      playerControllerLayerDisappearTime = newDisappearTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        onBackPressed(context);
      },
      child: SettingsDetailScaffold(
        title: const Text('Playback Settings'),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Decoding & Rendering'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.memory_rounded,
                  onToggle: (value) async {
                    hAenable = value ?? !hAenable;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.hAenable, hAenable);
                    setState(() {});
                  },
                  title: Text('Hardware Decoding'),
                  initialValue: hAenable,
                ),
                SettingsTile(
                  leading: Icons.developer_board_rounded,
                  onPressed: (_) async {
                    await context.pushNamed('/settings/player/decoder');
                  },
                  title: Text('Hardware Decoder'),
                  description: Text('Only takes effect when hardware decoding is enabled'),
                ),
                if (Platform.isAndroid) ...[
                  SettingsTile(
                    leading: Icons.tv_rounded,
                    onPressed: (_) async {
                      await context.pushNamed('/settings/player/renderer');
                    },
                    title: Text('Video Renderer'),
                    description: Text('Choose Video Output Method'),
                  ),
                ],
                SettingsTile.switchTile(
                  leading: Icons.data_saver_on_rounded,
                  enabled: !MeteredNetworkService.isMetered,
                  onToggle: (value) async {
                    lowMemoryMode = value ?? !lowMemoryMode;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.lowMemoryMode, lowMemoryMode);
                    setState(() {});
                  },
                  title: Text('Low Memory Mode'),
                  description: Text(MeteredNetworkService.isMetered
                      ? 'Automatically enabled on mobile networks'
                      : 'Disable advanced caching to reduce memory usage'),
                  // Effective state, not the stored one, which stays untouched.
                  initialValue:
                      lowMemoryMode || MeteredNetworkService.isMetered,
                ),
                if (Platform.isAndroid) ...[
                  SettingsTile.switchTile(
                    leading: Icons.graphic_eq_rounded,
                    onToggle: (value) async {
                      androidEnableOpenSLES = value ?? !androidEnableOpenSLES;
                      await GStorage.putSetting<bool>(
                          SettingsKeys.androidEnableOpenSLES,
                          androidEnableOpenSLES);
                      setState(() {});
                    },
                    title: Text('Low Latency Audio'),
                    description: Text('Enable OpenSLES audio output to reduce latency'),
                    initialValue: androidEnableOpenSLES,
                  ),
                ],
                SettingsTile(
                  leading: Icons.auto_awesome_rounded,
                  onPressed: (_) async {
                    context.pushNamed('/settings/player/super');
                  },
                  title: Text('Super Resolution'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Playback Behavior'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.headphones_rounded,
                  onToggle: (value) async {
                    backgroundPlayback = value ?? !backgroundPlayback;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.backgroundPlayback, backgroundPlayback);
                    setState(() {});
                  },
                  title: Text('Background Playback'),
                  description: Text('Continue playing audio when the app is backgrounded or the screen is off'),
                  initialValue: backgroundPlayback,
                ),
                SettingsTile.switchTile(
                  leading: Icons.history_rounded,
                  onToggle: (value) async {
                    playResume = value ?? !playResume;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.playResume, playResume);
                    setState(() {});
                  },
                  title: Text('Auto Skip'),
                  description: Text('Jump to Last Playback Position'),
                  initialValue: playResume,
                ),
                SettingsTile.switchTile(
                  leading: Icons.playlist_play_rounded,
                  onToggle: (value) async {
                    autoPlayNext = value ?? !autoPlayNext;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.autoPlayNext, autoPlayNext);
                    setState(() {});
                  },
                  title: Text('Auto Play Next'),
                  description: Text('Automatically play the next episode after the current video ends'),
                  initialValue: autoPlayNext,
                ),
                if (Platform.isAndroid)
                  SettingsTile.switchTile(
                    leading: Icons.picture_in_picture_alt_rounded,
                    onToggle: (value) async {
                      androidAutoEnterPIP = value ?? !androidAutoEnterPIP;
                      await GStorage.putSetting<bool>(
                          SettingsKeys.androidAutoEnterPIP,
                          androidAutoEnterPIP);
                      await PipUtils.setAndroidAutoEnterPIPEnabled(
                          androidAutoEnterPIP);
                      setState(() {});
                    },
                    title: Text('Auto Enter Picture-in-Picture'),
                    description: Text('Automatically enter picture-in-picture when moving to the background'),
                    initialValue: androidAutoEnterPIP,
                  ),
                SettingsTile.switchTile(
                  leading: Icons.block_rounded,
                  onToggle: (value) async {
                    forceAdBlocker = value ?? !forceAdBlocker;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.forceAdBlocker, forceAdBlocker);
                    setState(() {});
                  },
                  title: Text('Ad Filtering'),
                  description: Text('Force-enable HLS ad filtering, ignoring rule settings'),
                  initialValue: forceAdBlocker,
                ),
                SettingsTile.switchTile(
                  leading: Icons.animation_rounded,
                  onToggle: (value) async {
                    playerDisableAnimations = value ?? !playerDisableAnimations;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.playerDisableAnimations,
                        playerDisableAnimations);
                    setState(() {});
                  },
                  title: Text('Disable Animations'),
                  description: Text('Disable transition animations within the player'),
                  initialValue: playerDisableAnimations,
                ),
                if (!isDesktop())
                  SettingsTile.switchTile(
                    leading: Icons.swipe_vertical_rounded,
                    onToggle: (value) async {
                      brightnessVolumeGesture =
                          value ?? !brightnessVolumeGesture;
                      await GStorage.putSetting<bool>(
                          SettingsKeys.brightnessVolumeGesture,
                          brightnessVolumeGesture);
                      setState(() {});
                    },
                    title: Text('Swipe Gestures'),
                    description: Text('Swipe vertically to adjust volume and brightness'),
                    initialValue: brightnessVolumeGesture,
                  ),
                SettingsTile.switchTile(
                  leading: Icons.visibility_off_rounded,
                  onToggle: (value) async {
                    privateMode = value ?? !privateMode;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.privateMode, privateMode);
                    setState(() {});
                  },
                  title: Text('Incognito Mode'),
                  description: Text('Do not keep watch history'),
                  initialValue: privateMode,
                ),
              ],
            ),
            SettingsSection(
              title: Text('Diagnostics'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.error_outline_rounded,
                  onToggle: (value) async {
                    showPlayerError = value ?? !showPlayerError;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.showPlayerError, showPlayerError);
                    setState(() {});
                  },
                  title: Text('Error Message'),
                  description: Text('Show internal player error messages'),
                  initialValue: showPlayerError,
                ),
                SettingsTile.switchTile(
                  leading: Icons.bug_report_rounded,
                  onToggle: (value) async {
                    playerDebugMode = value ?? !playerDebugMode;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.playerDebugMode, playerDebugMode);
                    setState(() {});
                  },
                  title: Text('Debug Mode'),
                  description: Text('Record internal player logs'),
                  initialValue: playerDebugMode,
                ),
                SettingsTile(
                  leading: Icons.receipt_long_rounded,
                  onPressed: (_) async {
                    if (playerLogLevelMenuController.isOpen) {
                      playerLogLevelMenuController.close();
                    } else {
                      playerLogLevelMenuController.open();
                    }
                  },
                  title: Text('Log Level'),
                  description: Text('Player Internal Log Level'),
                  value: MenuAnchor(
                    consumeOutsideTap: true,
                    controller: playerLogLevelMenuController,
                    builder: (_, __, ___) {
                      return Text(
                        playerLogLevelMap[playerLogLevel] ?? '???',
                      );
                    },
                    menuChildren: [
                      for (final entry in playerLogLevelMap.entries)
                        MenuItemButton(
                          requestFocusOnHover: false,
                          onPressed: () => updatePlayerLogLevel(entry.key),
                          child: Container(
                            height: 48,
                            constraints: BoxConstraints(minWidth: 112),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: entry.key == playerLogLevel
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Playback Parameters'),
              tiles: [
                SettingsSliderTile(
                  leading: Icons.speed_rounded,
                  title: Text('Default Speed'),
                  value: defaultPlaySpeed,
                  min: 0.25,
                  max: 3,
                  divisions: 11,
                  valueLabel: '${defaultPlaySpeed}x',
                  onChanged: (value) => updateDefaultPlaySpeed(
                      double.parse(value.toStringAsFixed(2))),
                ),
                SettingsSliderTile(
                  leading: Icons.fast_forward_rounded,
                  title: Text('Hold for Speed'),
                  description: Text('Speed used when holding the screen or an arrow key'),
                  value: defaultShortcutForwardPlaySpeed,
                  min: 1.25,
                  max: 3,
                  divisions: 7,
                  valueLabel: '${defaultShortcutForwardPlaySpeed}x',
                  onChanged: (value) => updateDefaultShortcutForwardPlaySpeed(
                      double.parse(value.toStringAsFixed(2))),
                ),
                SettingsSliderTile(
                  leading: Icons.swap_horiz_rounded,
                  title: Text('Arrow Key Seek'),
                  description: Text('Seconds to seek with the left/right arrow keys'),
                  value: playerArrowKeySkipTime.toDouble(),
                  min: 0,
                  max: 15,
                  divisions: 15,
                  valueLabel: '$playerArrowKeySkipTime sec',
                  onChanged: (value) {
                    final newArrowKeySkipTime = value.toInt();
                    if (newArrowKeySkipTime == playerArrowKeySkipTime) {
                      return;
                    }
                    GStorage.putSetting<int>(
                        SettingsKeys.arrowKeySkipTime, newArrowKeySkipTime);
                    setState(() {
                      playerArrowKeySkipTime = newArrowKeySkipTime;
                    });
                  },
                ),
                SettingsTile(
                  leading: Icons.skip_next_rounded,
                  onPressed: (_) async {
                    await updateButtonSkipTime();
                  },
                  title: Text('Skip Duration'),
                  description: Text('Seconds skipped by the top bar skip button'),
                  value: Text('$playerButtonSkipTime sec'),
                ),
                SettingsSliderTile(
                  leading: Icons.timer_rounded,
                  title: Text('Control Bar Auto-hide Delay'),
                  description: Text('Time before the playback controller auto-hides'),
                  value: playerControllerLayerDisappearSeconds,
                  min: _minPlayerControllerLayerDisappearSeconds,
                  max: _maxPlayerControllerLayerDisappearSeconds,
                  divisions: _playerControllerLayerDisappearDivisions,
                  valueLabel: formatPlayerControllerLayerDisappearSeconds(
                      playerControllerLayerDisappearSeconds),
                  onChanged: updatePlayerControllerLayerDisappearSeconds,
                ),
                SettingsTile(
                  leading: Icons.aspect_ratio_rounded,
                  onPressed: (_) async {
                    if (playerAspectRatioMenuController.isOpen) {
                      playerAspectRatioMenuController.close();
                    } else {
                      playerAspectRatioMenuController.open();
                    }
                  },
                  title: Text('Default Video Aspect Ratio'),
                  value: MenuAnchor(
                    consumeOutsideTap: true,
                    controller: playerAspectRatioMenuController,
                    builder: (_, __, ___) {
                      return Text(
                        defaultAspectRatioMode.label,
                      );
                    },
                    menuChildren: [
                      for (final aspectRatioMode in PlayerAspectRatio.values)
                        MenuItemButton(
                          requestFocusOnHover: false,
                          onPressed: () =>
                              updateDefaultAspectRatioMode(aspectRatioMode),
                          child: Container(
                            height: 48,
                            constraints: BoxConstraints(minWidth: 112),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                aspectRatioMode.label,
                                style: TextStyle(
                                  color: aspectRatioMode ==
                                          defaultAspectRatioMode
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            SettingsSection(
              tiles: [
                SettingsTile(
                  leading: Icons.settings_backup_restore_rounded,
                  onPressed: (_) => resetPlayerSettings(),
                  title: Text('Restore Default Settings'),
                  description: Text('Reset playback-related settings to default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

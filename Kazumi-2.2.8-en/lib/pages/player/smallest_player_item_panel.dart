import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kazumi/bean/widget/play_pause_icon.dart';
import 'package:kazumi/pages/player/player_adjustment_hud.dart';
import 'package:kazumi/pages/player/controller/player_aspect_ratio.dart';
import 'package:kazumi/pages/player/controller/player_super_resolution.dart';
import 'package:kazumi/pages/player/player_panel_hold.dart';
import 'package:kazumi/services/player/pip_utils.dart';
import 'package:kazumi/pages/video/video_controller.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/pages/player/player_controller.dart';
import 'package:flutter/services.dart';
import 'package:kazumi/services/player/remote.dart';
import 'package:kazumi/pages/settings/danmaku/danmaku_settings_sheet.dart';
import 'package:kazumi/utils/constants.dart';
import 'package:kazumi/bean/appbar/drag_to_move_bar.dart' as dtb;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:kazumi/bean/widget/embedded_native_control_area.dart';
import 'package:kazumi/services/player/timed_shutdown_service.dart';
import 'package:kazumi/utils/device.dart';
import 'package:kazumi/utils/format.dart';

class SmallestPlayerItemPanel extends StatefulWidget {
  const SmallestPlayerItemPanel({
    super.key,
    required this.playerController,
    required this.videoPageController,
    required this.onBackPressed,
    required this.setPlaybackSpeed,
    required this.showDanmakuSwitch,
    required this.handleFullscreen,
    required this.handleProgressBarDragStart,
    required this.handleProgressBarSeek,
    required this.handleSuperResolutionChange,
    required this.panelVisibilityController,
    required this.acquirePlayerPanelHold,
    required this.onMenuVisibilityChanged,
    required this.handleDanmaku,
    required this.skipOP,
    required this.showVideoInfo,
    required this.showSyncPlayPanel,
    required this.pauseForTimedShutdown,
    this.disableAnimations = false,
  });

  final PlayerController playerController;
  final VideoPageController videoPageController;
  final void Function(BuildContext) onBackPressed;
  final Future<void> Function(double) setPlaybackSpeed;
  final void Function() showDanmakuSwitch;
  final void Function() handleDanmaku;
  final void Function() skipOP;
  final void Function() handleFullscreen;
  final VoidCallback handleProgressBarDragStart;
  final Future<void> Function(Duration duration) handleProgressBarSeek;
  final Future<void> Function(SuperResolutionMode mode)
      handleSuperResolutionChange;
  final AnimationController panelVisibilityController;
  final PlayerPanelHold Function() acquirePlayerPanelHold;
  final ValueChanged<bool> onMenuVisibilityChanged;
  final void Function() showVideoInfo;
  final void Function() showSyncPlayPanel;
  final VoidCallback pauseForTimedShutdown;
  final bool disableAnimations;

  @override
  State<SmallestPlayerItemPanel> createState() =>
      _SmallestPlayerItemPanelState();
}

class _SmallestPlayerItemPanelState extends State<SmallestPlayerItemPanel> {
  late Animation<Offset> topOffsetAnimation;
  late Animation<Offset> bottomOffsetAnimation;
  late final VideoPageController videoPageController =
      widget.videoPageController;
  late final PlayerController playerController;

  String? cachedSvgString;
  Widget? cachedDanmakuOnIcon;
  Widget? cachedDanmakuOffIcon;

  static const double _danmakuIconSize = 24.0;
  static const double _loadingIndicatorStrokeWidth = 2.0;

  void showForwardChange() {
    KazumiDialog.show(builder: (context) {
      String input = "";
      return AlertDialog(
        title: const Text('Skip Seconds'),
        content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return TextField(
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelText: playerController.playback.buttonSkipTime.toString(),
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
              if (input != "") {
                playerController.setButtonForwardTime(int.parse(input));
                KazumiDialog.dismiss();
              } else {
                KazumiDialog.dismiss();
              }
            },
            child: const Text('OK'),
          ),
        ],
      );
    });
  }

  @override
  void initState() {
    super.initState();
    playerController = widget.playerController;
    topOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: widget.panelVisibilityController,
      curve: Curves.easeInOut,
    ));
    bottomOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: widget.panelVisibilityController,
      curve: Curves.easeInOut,
    ));
    cacheSvgIcons();
  }

  void cacheSvgIcons() {
    cachedDanmakuOffIcon = RepaintBoundary(
      child: SvgPicture.asset(
        'assets/images/danmaku_off.svg',
        height: _danmakuIconSize,
      ),
    );
  }

  Widget danmakuOnIcon(BuildContext context) {
    final colorHex = Theme.of(context)
        .colorScheme
        .primary
        .toARGB32()
        .toRadixString(16)
        .substring(2);

    if (cachedSvgString != colorHex) {
      cachedSvgString = colorHex;
      final svgString = danmakuOnSvg.replaceFirst('00AEEC', colorHex);
      cachedDanmakuOnIcon = RepaintBoundary(
        child: SvgPicture.string(
          svgString,
          height: _danmakuIconSize,
        ),
      );
    }

    return cachedDanmakuOnIcon!;
  }

  Widget _buildDanmakuToggleButton(BuildContext context) {
    return Observer(builder: (context) {
      final danmakuLoading = playerController.danmaku.danmakuLoading;
      final danmakuOn = playerController.danmaku.danmakuOn;
      return IconButton(
        color: Colors.white,
        icon: danmakuLoading
            ? SizedBox(
                width: _danmakuIconSize,
                height: _danmakuIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: _loadingIndicatorStrokeWidth,
                ),
              )
            : (danmakuOn ? danmakuOnIcon(context) : cachedDanmakuOffIcon!),
        onPressed: danmakuLoading
            ? null
            : () {
                widget.handleDanmaku();
              },
        tooltip: danmakuLoading ? 'Loading danmaku...' : (danmakuOn ? 'Turn Off Danmaku' : 'Turn On Danmaku'),
      );
    });
  }

  Widget forwardIcon() {
    return Tooltip(
      message: 'Fast forward ${playerController.playback.buttonSkipTime}s, hold to change duration',
      child: GestureDetector(
        onLongPress: () => showForwardChange(),
        child: IconButton(
          icon: Image.asset(
            'assets/images/forward_80.png',
            color: Colors.white,
            height: 24,
          ),
          onPressed: () {
            widget.skipOP();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedPositioned(
          duration: const Duration(seconds: 1),
          top: 0,
          left: 0,
          right: 0,
          child: Observer(builder: (context) {
            return Visibility(
              visible: !playerController.panel.lockPanel &&
                  (widget.disableAnimations
                      ? playerController.panel.showVideoController
                      : true),
              child: widget.disableAnimations
                  ? Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black45,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    )
                  : SlideTransition(
                      position: topOffsetAnimation,
                      child: Container(
                        height: 50,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black45,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
            );
          }),
        ),
        AnimatedPositioned(
          duration: const Duration(seconds: 1),
          bottom: 0,
          left: 0,
          right: 0,
          child: Observer(builder: (context) {
            return Visibility(
              visible: !playerController.panel.lockPanel &&
                  (widget.disableAnimations
                      ? playerController.panel.showVideoController
                      : true),
              child: widget.disableAnimations
                  ? Container(
                      height: 100,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black45,
                          ],
                        ),
                      ),
                    )
                  : SlideTransition(
                      position: bottomOffsetAnimation,
                      child: Container(
                        height: 100,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black45,
                            ],
                          ),
                        ),
                      ),
                    ),
            );
          }),
        ),
        Positioned(
          top: 25,
          child: Observer(builder: (context) {
            // PlayerSeekHud latches values only while visible, so skipping the
            // position reads when hidden keeps the 1s tick from rebuilding this.
            final visible = playerController.panel.showSeekTime;
            return PlayerSeekHud(
              visible: visible,
              currentPosition: visible
                  ? playerController.playback.currentPosition
                  : Duration.zero,
              playerPosition: visible
                  ? playerController.playback.playerPosition
                  : Duration.zero,
              duration:
                  visible ? playerController.playback.duration : Duration.zero,
              direction: playerController.panel.seekDirection,
              disableAnimations: widget.disableAnimations,
            );
          }),
        ),
        Positioned(
          top: 25,
          child: Observer(builder: (context) {
            return PlayerSpeedHud(
              visible: playerController.panel.showPlaySpeed,
              speed: playerController.playback.playerSpeed,
              disableAnimations: widget.disableAnimations,
            );
          }),
        ),
        Positioned(
          top: 25,
          child: Observer(builder: (context) {
            final showVolume = playerController.panel.showVolume;
            final showBrightness = playerController.panel.showBrightness;
            return PlayerAdjustmentHud(
              visible: showVolume || showBrightness,
              type: showVolume
                  ? PlayerAdjustmentHudType.volume
                  : PlayerAdjustmentHudType.brightness,
              value: showVolume
                  ? playerController.playback.volume
                  : playerController.panel.brightness,
              disableAnimations: widget.disableAnimations,
            );
          }),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Observer(builder: (context) {
            return Visibility(
              visible: !playerController.panel.lockPanel &&
                  (widget.disableAnimations
                      ? playerController.panel.showVideoController
                      : true),
              child: widget.disableAnimations
                  ? topControlWidget
                  : SlideTransition(
                      position: topOffsetAnimation, child: topControlWidget),
            );
          }),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Observer(builder: (context) {
            return Visibility(
              visible: !playerController.panel.lockPanel &&
                  (widget.disableAnimations
                      ? playerController.panel.showVideoController
                      : true),
              child: widget.disableAnimations
                  ? bottomControlWidget
                  : SlideTransition(
                      position: bottomOffsetAnimation,
                      child: bottomControlWidget),
            );
          }),
        ),
      ],
    );
  }

  Widget get bottomControlWidget {
    return Row(
      children: [
        IconButton(
          icon: PlayPauseIcon(
            iconColor: Colors.white,
            playing: playerController.playback.playing,
          ),
          tooltip: playerController.playback.playing ? 'Pause' : 'Play',
          onPressed: () {
            playerController.playOrPause();
          },
        ),
        // Position reads stay inside these narrow Observers so the 1s progress
        // tick rebuilds only the bar and time text, not the whole bottom bar.
        Expanded(
          child: Observer(builder: (context) {
            return ProgressBar(
              thumbRadius: 8,
              thumbGlowRadius: 18,
              timeLabelLocation: TimeLabelLocation.none,
              progress: playerController.playback.currentPosition,
              buffered: playerController.playback.buffer,
              total: playerController.playback.duration,
              onSeek: widget.handleProgressBarSeek,
              onDragStart: (_) => widget.handleProgressBarDragStart(),
              onDragUpdate: (details) => playerController.seeking
                  .updateInteractiveSeek(details.timeStamp),
            );
          }),
        ),
        Observer(builder: (context) {
          return Text(
            "    ${durationToString(playerController.playback.currentPosition)} / ${durationToString(playerController.playback.duration)}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.0,
              fontFeatures: [
                FontFeature.tabularFigures(),
              ],
            ),
          );
        }),
        (!videoPageController.isPip)
            ? IconButton(
                color: Colors.white,
                icon: Icon(videoPageController.isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded),
                tooltip: videoPageController.isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                onPressed: () {
                  widget.handleFullscreen();
                },
              )
            : const Text('    '),
      ],
    );
  }

  Widget get topControlWidget {
    return EmbeddedNativeControlArea(
      child: Row(
        children: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () {
              widget.onBackPressed(context);
            },
          ),
          const Expanded(
            child: dtb.DragToMoveArea(child: SizedBox(height: 40)),
          ),
          forwardIcon(),
          if (isDesktop() || Platform.isAndroid)
            IconButton(
                onPressed: () async {
                  if (isDesktop()) {
                    if (videoPageController.isPip) {
                      await PipUtils.exitDesktopPIPWindow();
                    } else {
                      // Size the PiP window to the video aspect ratio to
                      // avoid letterboxing.
                      await PipUtils.enterDesktopPIPWindow(
                        width: playerController.debug.playerWidth,
                        height: playerController.debug.playerHeight,
                      );
                    }
                    videoPageController.isPip = !videoPageController.isPip;
                    return;
                  }
                  final bool supported = await PipUtils.isAndroidPIPSupported();
                  if (!supported) {
                    KazumiDialog.showToast(message: 'Picture-in-picture is not supported on this device');
                    return;
                  }
                  await PipUtils.updateAndroidPIPActions(
                    playing: playerController.playback.playing,
                    danmakuEnabled: playerController.danmaku.danmakuOn,
                    width: playerController.debug.playerWidth,
                    height: playerController.debug.playerHeight,
                  );
                  final bool entered = await PipUtils.enterAndroidPIPWindow(
                    width: playerController.debug.playerWidth,
                    height: playerController.debug.playerHeight,
                  );
                  if (!entered) {
                    KazumiDialog.showToast(message: 'Failed to enter picture-in-picture');
                  }
                },
                tooltip: 'Picture-in-Picture',
                icon:
                    const Icon(Icons.picture_in_picture, color: Colors.white)),
          _buildDanmakuToggleButton(context),
          PlayerPanelHoldCollectButton(
            acquirePlayerPanelHold: widget.acquirePlayerPanelHold,
            bangumiItem: videoPageController.bangumiItem,
          ),
          PlayerPanelHoldMenuAnchor(
            acquirePlayerPanelHold: widget.acquirePlayerPanelHold,
            onVisibilityChanged: widget.onMenuVisibilityChanged,
            consumeOutsideTap: true,
            builder: (BuildContext context, MenuController controller,
                Widget? child) {
              return IconButton(
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                tooltip: 'More Options',
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
              );
            },
            menuChildren: [
              SubmenuButton(
                menuChildren: [
                  for (final aspectRatioMode in PlayerAspectRatio.values)
                    MenuItemButton(
                      onPressed: () => playerController.panel.aspectRatioMode =
                          aspectRatioMode,
                      child: Container(
                        height: 48,
                        constraints: BoxConstraints(minWidth: 112),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            aspectRatioMode.label,
                            style: TextStyle(
                                color: aspectRatioMode ==
                                        playerController.panel.aspectRatioMode
                                    ? Theme.of(context).colorScheme.primary
                                    : null),
                          ),
                        ),
                      ),
                    ),
                ],
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Video Aspect Ratio"),
                  ),
                ),
              ),
              SubmenuButton(
                menuChildren: [
                  for (final double i
                      in defaultPlaySpeedList) ...<MenuItemButton>[
                    MenuItemButton(
                      onPressed: () async {
                        await widget.setPlaybackSpeed(i);
                      },
                      child: Container(
                        height: 48,
                        constraints: BoxConstraints(minWidth: 112),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${i}x',
                            style: TextStyle(
                                color:
                                    i == playerController.playback.playerSpeed
                                        ? Theme.of(context).colorScheme.primary
                                        : null),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Speed"),
                  ),
                ),
              ),
              SubmenuButton(
                menuChildren: [
                  for (final mode in SuperResolutionMode.values)
                    MenuItemButton(
                      onPressed: () => widget.handleSuperResolutionChange(mode),
                      child: Container(
                        height: 48,
                        constraints: BoxConstraints(minWidth: 112),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            mode.label,
                            style: TextStyle(
                              color: playerController
                                          .playback.superResolutionMode ==
                                      mode
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Super Resolution"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  widget.showSyncPlayPanel();
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Watch Together"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  widget.showDanmakuSwitch();
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Toggle Danmaku"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  showDanmakuSettingsSheet(
                    context: context,
                    danmakuController:
                        playerController.danmaku.canvasController,
                    onUpdateDanmakuSpeed: playerController.updateDanmakuSpeed,
                    onTimelineOffsetChanged: playerController
                        .danmaku.clearAndInvalidateScheduledDanmakus,
                  );
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Danmaku Settings"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  widget.showVideoInfo();
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Video Details"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  bool needRestart = playerController.playback.playing;
                  playerController.pause();
                  RemotePlay()
                      .castVideo(playerController.videoUrl,
                          videoPageController.currentPlugin.referer)
                      .whenComplete(() {
                    if (mounted && needRestart) {
                      playerController.play();
                    }
                  });
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Remote Cast"),
                  ),
                ),
              ),
              MenuItemButton(
                onPressed: () {
                  playerController.launchExternalPlayer();
                },
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("External Player"),
                  ),
                ),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () {
                      TimedShutdownService().cancel();
                    },
                    child: Container(
                      height: 48,
                      constraints: BoxConstraints(minWidth: 112),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Off",
                          style: TextStyle(
                            color: !TimedShutdownService().isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final int minutes in [15, 30, 60])
                    MenuItemButton(
                      onPressed: () {
                        TimedShutdownService().start(minutes,
                            onExpired: widget.pauseForTimedShutdown);
                        KazumiDialog.showToast(
                            message:
                                'Sleep timer set for ${TimedShutdownService().formatMinutesToDisplay(minutes)}');
                      },
                      child: Container(
                        height: 48,
                        constraints: BoxConstraints(minWidth: 112),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "$minutes min",
                            style: TextStyle(
                              color:
                                  TimedShutdownService().setMinutes == minutes
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  MenuItemButton(
                    onPressed: () {
                      TimedShutdownService.showCustomTimerDialog(
                        onExpired: widget.pauseForTimedShutdown,
                      );
                    },
                    child: Container(
                      height: 48,
                      constraints: BoxConstraints(minWidth: 112),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Custom"),
                      ),
                    ),
                  ),
                ],
                child: Container(
                  height: 48,
                  constraints: BoxConstraints(minWidth: 112),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ValueListenableBuilder<int>(
                      valueListenable:
                          TimedShutdownService().remainingSecondsNotifier,
                      builder: (context, remainingSeconds, child) {
                        return Text(
                          remainingSeconds > 0
                              ? "Sleep Timer (${TimedShutdownService().formatRemainingTime()})"
                              : "Sleep Timer",
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

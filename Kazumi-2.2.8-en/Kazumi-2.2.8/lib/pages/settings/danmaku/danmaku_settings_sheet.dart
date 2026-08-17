import 'package:canvas_danmaku/canvas_danmaku.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/adaptive_bottom_sheet.dart';
import 'package:kazumi/bean/dialog/material_bottom_sheet.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/pages/settings/danmaku/danmaku_shield_settings_sheet.dart';
import 'package:kazumi/pages/settings/danmaku/danmaku_time_offset_sheet.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/utils/device.dart';

enum _DanmakuSettingsDestination {
  timeOffset,
}

Future<void> showDanmakuSettingsSheet({
  required BuildContext context,
  required DanmakuController danmakuController,
  VoidCallback? onUpdateDanmakuSpeed,
  VoidCallback? onTimelineOffsetChanged,
}) async {
  final destination =
      await showAdaptiveBottomSheet<_DanmakuSettingsDestination>(
    context: context,
    builder: (context) {
      return _DanmakuSettingsSheet(
        danmakuController: danmakuController,
        onUpdateDanmakuSpeed: onUpdateDanmakuSpeed,
      );
    },
  );

  if (!context.mounted ||
      destination != _DanmakuSettingsDestination.timeOffset) {
    return;
  }

  await showAdaptiveBottomSheet<void>(
    context: context,
    builder: (context) {
      return DanmakuTimeOffsetSheet(
        onTimelineOffsetChanged: onTimelineOffsetChanged,
      );
    },
  );
}

class _DanmakuSettingsSheet extends StatefulWidget {
  final DanmakuController danmakuController;
  final VoidCallback? onUpdateDanmakuSpeed;

  const _DanmakuSettingsSheet({
    required this.danmakuController,
    this.onUpdateDanmakuSpeed,
  });

  @override
  State<_DanmakuSettingsSheet> createState() => _DanmakuSettingsSheetState();
}

class _DanmakuSettingsSheetState extends State<_DanmakuSettingsSheet> {
  DanmakuOption get _option => widget.danmakuController.option;

  void _applyOption(DanmakuOption option) {
    setState(() => widget.danmakuController.updateOption(option));
  }

  void _showDanmakuShieldSheet() {
    showAdaptiveBottomSheet<void>(
      context: context,
      builder: (context) => const DanmakuShieldSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Scaffold(
        body: Column(
          children: [
            MaterialBottomSheetHeader(
              title: 'Danmaku Settings',
              description: 'Adjust danmaku display, style, and filter rules',
              onClose: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: SettingsList(
                sections: [
                  SettingsSection(
                    title: Text('Danmaku Filter'),
                    tiles: [
                      SettingsTile(
                        leading: Icons.block_rounded,
                        onPressed: (_) {
                          _showDanmakuShieldSheet();
                        },
                        title: Text('Keyword Filter'),
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: Text('Danmaku Style'),
                    tiles: [
                      SettingsSliderTile(
                        leading: Icons.format_size_rounded,
                        title: Text('Font Size'),
                        value: _option.fontSize,
                        min: 10,
                        max: isCompact() ? 32 : 48,
                        valueLabel: '${_option.fontSize.floor()}',
                        onChanged: (value) {
                          final fontSize = value.floorToDouble();
                          _applyOption(_option.copyWith(fontSize: fontSize));
                          GStorage.putSetting<double>(
                              SettingsKeys.danmakuFontSize, fontSize);
                        },
                      ),
                      SettingsSliderTile(
                        leading: Icons.opacity_rounded,
                        title: Text('Danmaku Opacity'),
                        value: _option.opacity,
                        min: 0.1,
                        max: 1,
                        valueLabel: '${(_option.opacity * 100).round()}%',
                        onChanged: (value) {
                          _applyOption(_option.copyWith(opacity: value));
                          GStorage.putSetting<double>(
                              SettingsKeys.danmakuOpacity,
                              double.parse(value.toStringAsFixed(2)));
                        },
                      ),
                    ],
                  ),
                  SettingsSection(
                    title: Text('Danmaku Display'),
                    tiles: [
                      SettingsTile(
                        leading: Icons.schedule_rounded,
                        onPressed: (context) {
                          Navigator.of(context)
                              .pop(_DanmakuSettingsDestination.timeOffset);
                        },
                        title: Text('Timeline Offset'),
                        value: Text(
                          formatDanmakuTimeOffset(
                            normalizeDanmakuTimeOffset(
                              GStorage.getSetting<double>(
                                  SettingsKeys.danmakuTimeOffset),
                            ),
                          ),
                        ),
                      ),
                      SettingsSliderTile(
                        leading: Icons.crop_free_rounded,
                        title: Text('Danmaku Area'),
                        value: _option.area,
                        min: 0,
                        max: 1,
                        divisions: 8,
                        valueLabel: '${(_option.area * 100).round()}%',
                        onChanged: (value) {
                          _applyOption(_option.copyWith(area: value));
                          GStorage.putSetting<double>(
                              SettingsKeys.danmakuArea, value);
                        },
                      ),
                      SettingsSliderTile(
                        leading: Icons.timer_rounded,
                        title: Text('Duration'),
                        value: _option.duration.toDouble(),
                        min: 2,
                        max: 16,
                        divisions: 14,
                        valueLabel: '${_option.duration.round()} sec',
                        onChanged: (value) {
                          _applyOption(_option.copyWith(duration: value));
                          GStorage.putSetting<double>(
                              SettingsKeys.danmakuDuration,
                              value.roundToDouble());
                        },
                      ),
                      SettingsSliderTile(
                        leading: Icons.format_line_spacing_rounded,
                        title: Text('Line Height'),
                        value: _option.lineHeight,
                        min: 0,
                        max: 3,
                        divisions: 30,
                        valueLabel: _option.lineHeight.toStringAsFixed(1),
                        onChanged: (value) {
                          final lineHeight =
                              double.parse(value.toStringAsFixed(1));
                          _applyOption(
                              _option.copyWith(lineHeight: lineHeight));
                          GStorage.putSetting<double>(
                              SettingsKeys.danmakuLineHeight, lineHeight);
                        },
                      ),
                      SettingsTile.switchTile(
                        leading: Icons.vertical_align_top_rounded,
                        onToggle: (value) {
                          final show = value ?? _option.hideTop;
                          _applyOption(_option.copyWith(hideTop: !show));
                          GStorage.putSetting<bool>(
                              SettingsKeys.danmakuTop, show);
                        },
                        title: Text('Top Danmaku'),
                        initialValue: !_option.hideTop,
                      ),
                      SettingsTile.switchTile(
                        leading: Icons.vertical_align_bottom_rounded,
                        onToggle: (value) {
                          final show = value ?? _option.hideBottom;
                          _applyOption(_option.copyWith(hideBottom: !show));
                          GStorage.putSetting<bool>(
                              SettingsKeys.danmakuBottom, show);
                        },
                        title: Text('Bottom Danmaku'),
                        initialValue: !_option.hideBottom,
                      ),
                      SettingsTile.switchTile(
                        leading: Icons.swap_horiz_rounded,
                        onToggle: (value) {
                          final show = value ?? _option.hideScroll;
                          _applyOption(_option.copyWith(hideScroll: !show));
                          GStorage.putSetting<bool>(
                              SettingsKeys.danmakuScroll, show);
                        },
                        title: Text('Scrolling Danmaku'),
                        initialValue: !_option.hideScroll,
                      ),
                      SettingsTile.switchTile(
                        leading: Icons.speed_rounded,
                        onToggle: (value) {
                          bool followSpeed = value ??
                              !GStorage.getSetting<bool>(
                                  SettingsKeys.danmakuFollowSpeed);
                          GStorage.putSetting<bool>(
                              SettingsKeys.danmakuFollowSpeed, followSpeed);
                          widget.onUpdateDanmakuSpeed?.call();
                          setState(() {});
                        },
                        title: Text('Follow Playback Speed'),
                        description: Text('Danmaku speed changes with playback speed'),
                        initialValue: GStorage.getSetting<bool>(
                            SettingsKeys.danmakuFollowSpeed),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/utils/device.dart';

class DanmakuSettingsPage extends StatefulWidget {
  const DanmakuSettingsPage({super.key});

  @override
  State<DanmakuSettingsPage> createState() => _DanmakuSettingsPageState();
}

class _DanmakuSettingsPageState extends State<DanmakuSettingsPage> {
  late final bool compactLayout;
  late double defaultDanmakuArea;
  late double defaultDanmakuOpacity;
  late double defaultDanmakuFontSize;
  late int defaultDanmakuFontWeight;
  late double defaultDanmakuDuration;
  late double defaultDanmakuLineHeight;
  late double defaultdanmakuBorderSize;
  late bool danmakuBorder;
  late bool danmakuTop;
  late bool danmakuBottom;
  late bool danmakuScroll;
  late bool danmakuColor;
  late bool danmakuMassive;
  late bool danmakuDeduplication;
  late bool danmakuBiliBiliSource;
  late bool danmakuGamerSource;
  late bool danmakuDanDanSource;
  late bool danmakuFollowSpeed;

  @override
  void initState() {
    super.initState();
    compactLayout = isCompact();
    _loadSettingsFromStorage();
  }

  void _loadSettingsFromStorage() {
    final settingContext = SettingContext(compactLayout: compactLayout);
    defaultDanmakuArea = GStorage.getSetting(SettingsKeys.danmakuArea);
    defaultDanmakuOpacity = GStorage.getSetting(SettingsKeys.danmakuOpacity);
    defaultDanmakuFontSize = GStorage.getSetting<double>(
        SettingsKeys.danmakuFontSize,
        context: settingContext);
    defaultDanmakuFontWeight =
        GStorage.getSetting(SettingsKeys.danmakuFontWeight);
    defaultDanmakuDuration = GStorage.getSetting(SettingsKeys.danmakuDuration);
    defaultDanmakuLineHeight =
        GStorage.getSetting(SettingsKeys.danmakuLineHeight);
    danmakuBorder = GStorage.getSetting(SettingsKeys.danmakuBorder);
    defaultdanmakuBorderSize =
        GStorage.getSetting(SettingsKeys.danmakuBorderSize);
    danmakuTop = GStorage.getSetting(SettingsKeys.danmakuTop);
    danmakuBottom = GStorage.getSetting(SettingsKeys.danmakuBottom);
    danmakuScroll = GStorage.getSetting(SettingsKeys.danmakuScroll);
    danmakuColor = GStorage.getSetting(SettingsKeys.danmakuColor);
    danmakuMassive = GStorage.getSetting(SettingsKeys.danmakuMassive);
    danmakuDeduplication =
        GStorage.getSetting<bool>(SettingsKeys.danmakuDeduplication);
    danmakuBiliBiliSource =
        GStorage.getSetting<bool>(SettingsKeys.danmakuBiliBiliSource);
    danmakuGamerSource =
        GStorage.getSetting<bool>(SettingsKeys.danmakuGamerSource);
    danmakuDanDanSource =
        GStorage.getSetting<bool>(SettingsKeys.danmakuDanDanSource);
    danmakuFollowSpeed =
        GStorage.getSetting<bool>(SettingsKeys.danmakuFollowSpeed);
  }

  Future<void> resetDanmakuSettings() async {
    final bool shouldReset = await KazumiDialog.show<bool>(
          builder: (context) => AlertDialog(
            title: const Text('Restore Default Danmaku Settings'),
            content: const Text('Danmaku source, display, and style settings will be reset to default. The keyword filter list will not be cleared.'),
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

    await GStorage.resetDanmakuSettings();
    if (!mounted) return;
    setState(_loadSettingsFromStorage);
    KazumiDialog.showToast(message: 'Danmaku settings restored to default');
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  void updateDanmakuArea(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuArea, i);
    setState(() {
      defaultDanmakuArea = i;
    });
  }

  void updateDanmakuOpacity(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuOpacity, i);
    setState(() {
      defaultDanmakuOpacity = i;
    });
  }

  void updateDanmakuFontSize(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuFontSize, i);
    setState(() {
      defaultDanmakuFontSize = i;
    });
  }

  void updateDanmakuDuration(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuDuration, i);
    setState(() {
      defaultDanmakuDuration = i;
    });
  }

  void updateDanmakuLineHeight(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuLineHeight, i);
    setState(() {
      defaultDanmakuLineHeight = i;
    });
  }

  void updateDanmakuFontWeight(int i) async {
    await GStorage.putSetting<int>(SettingsKeys.danmakuFontWeight, i);
    setState(() {
      defaultDanmakuFontWeight = i;
    });
  }

  void updateDanmakuBorderSize(double i) async {
    await GStorage.putSetting<double>(SettingsKeys.danmakuBorderSize, i);
    setState(() {
      defaultdanmakuBorderSize = i;
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
        title: const Text('Danmaku Settings'),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Danmaku Source'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.live_tv_rounded,
                  onToggle: (value) async {
                    danmakuBiliBiliSource = value ?? !danmakuBiliBiliSource;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuBiliBiliSource,
                        danmakuBiliBiliSource);
                    setState(() {});
                  },
                  title: Text('BiliBili'),
                  initialValue: danmakuBiliBiliSource,
                ),
                SettingsTile.switchTile(
                  leading: Icons.sports_esports_rounded,
                  onToggle: (value) async {
                    danmakuGamerSource = value ?? !danmakuGamerSource;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuGamerSource, danmakuGamerSource);
                    setState(() {});
                  },
                  title: Text('Gamer'),
                  initialValue: danmakuGamerSource,
                ),
                SettingsTile.switchTile(
                  leading: Icons.forum_rounded,
                  onToggle: (value) async {
                    danmakuDanDanSource = value ?? !danmakuDanDanSource;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuDanDanSource, danmakuDanDanSource);
                    setState(() {});
                  },
                  title: Text('DanDanPlay'),
                  initialValue: danmakuDanDanSource,
                ),
              ],
            ),
            SettingsSection(
              title: Text('Danmaku Filter'),
              tiles: [
                SettingsTile(
                  leading: Icons.block_rounded,
                  onPressed: (_) {
                    context.pushNamed('/settings/danmaku/shield');
                  },
                  title: Text('Keyword Filter'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Danmaku Display'),
              tiles: [
                SettingsSliderTile(
                  leading: Icons.crop_free_rounded,
                  title: Text('Danmaku Area'),
                  value: defaultDanmakuArea,
                  min: 0,
                  max: 1,
                  divisions: 8,
                  valueLabel: '${(defaultDanmakuArea * 100).round()}%',
                  onChanged: updateDanmakuArea,
                ),
                SettingsSliderTile(
                  leading: Icons.timer_rounded,
                  title: Text('Danmaku Duration'),
                  value: defaultDanmakuDuration,
                  min: 2,
                  max: 16,
                  divisions: 14,
                  valueLabel: '${defaultDanmakuDuration.round()} sec',
                  onChanged: (value) =>
                      updateDanmakuDuration(value.roundToDouble()),
                ),
                SettingsSliderTile(
                  leading: Icons.format_line_spacing_rounded,
                  title: Text('Danmaku Line Height'),
                  value: defaultDanmakuLineHeight,
                  min: 0,
                  max: 3,
                  divisions: 30,
                  valueLabel: defaultDanmakuLineHeight.toStringAsFixed(1),
                  onChanged: (value) => updateDanmakuLineHeight(
                      double.parse(value.toStringAsFixed(1))),
                ),
                SettingsTile.switchTile(
                  leading: Icons.speed_rounded,
                  onToggle: (value) async {
                    danmakuFollowSpeed = value ?? !danmakuFollowSpeed;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuFollowSpeed, danmakuFollowSpeed);
                    setState(() {});
                  },
                  title: Text('Danmaku Follows Playback Speed'),
                  description: Text('When enabled, danmaku speed changes with video playback speed'),
                  initialValue: danmakuFollowSpeed,
                ),
                SettingsTile.switchTile(
                  leading: Icons.vertical_align_top_rounded,
                  onToggle: (value) async {
                    danmakuTop = value ?? !danmakuTop;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuTop, danmakuTop);
                    setState(() {});
                  },
                  title: Text('Top Danmaku'),
                  initialValue: danmakuTop,
                ),
                SettingsTile.switchTile(
                  leading: Icons.vertical_align_bottom_rounded,
                  onToggle: (value) async {
                    danmakuBottom = value ?? !danmakuBottom;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuBottom, danmakuBottom);
                    setState(() {});
                  },
                  title: Text('Bottom Danmaku'),
                  initialValue: danmakuBottom,
                ),
                SettingsTile.switchTile(
                  leading: Icons.swap_horiz_rounded,
                  onToggle: (value) async {
                    danmakuScroll = value ?? !danmakuScroll;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuScroll, danmakuScroll);
                    setState(() {});
                  },
                  title: Text('Scrolling Danmaku'),
                  initialValue: danmakuScroll,
                ),
                SettingsTile.switchTile(
                  leading: Icons.layers_rounded,
                  onToggle: (value) async {
                    danmakuMassive = value ?? !danmakuMassive;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuMassive, danmakuMassive);
                    setState(() {});
                  },
                  title: Text('Massive Danmaku'),
                  description: Text('Overlay rendering when there is too much danmaku'),
                  initialValue: danmakuMassive,
                ),
                SettingsTile.switchTile(
                  leading: Icons.filter_alt_rounded,
                  onToggle: (value) async {
                    danmakuDeduplication = value ?? !danmakuDeduplication;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuDeduplication,
                        danmakuDeduplication);
                    setState(() {});
                  },
                  title: Text('Danmaku Deduplication'),
                  description: Text('Merge into one when there is too much danmaku with identical content'),
                  initialValue: danmakuDeduplication,
                ),
              ],
            ),
            SettingsSection(
              title: Text('Danmaku Style'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.border_color_rounded,
                  onToggle: (value) async {
                    danmakuBorder = value ?? !danmakuBorder;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuBorder, danmakuBorder);
                    setState(() {});
                  },
                  title: Text('Danmaku Outline'),
                  initialValue: danmakuBorder,
                ),
                SettingsSliderTile(
                  leading: Icons.line_weight_rounded,
                  title: Text('Danmaku Outline Thickness'),
                  value: defaultdanmakuBorderSize,
                  min: 0.1,
                  max: 3,
                  divisions: 29,
                  valueLabel: defaultdanmakuBorderSize.toStringAsFixed(1),
                  onChanged: (value) => updateDanmakuBorderSize(
                      double.parse(value.toStringAsFixed(1))),
                ),
                SettingsTile.switchTile(
                  leading: Icons.palette_rounded,
                  onToggle: (value) async {
                    danmakuColor = value ?? !danmakuColor;
                    await GStorage.putSetting<bool>(
                        SettingsKeys.danmakuColor, danmakuColor);
                    setState(() {});
                  },
                  title: Text('Danmaku Color'),
                  initialValue: danmakuColor,
                ),
                SettingsSliderTile(
                  leading: Icons.format_size_rounded,
                  title: Text('Font Size'),
                  value: defaultDanmakuFontSize,
                  min: 10,
                  max: isCompact() ? 32 : 48,
                  valueLabel: '${defaultDanmakuFontSize.floor()}',
                  onChanged: (value) =>
                      updateDanmakuFontSize(value.floorToDouble()),
                ),
                SettingsSliderTile(
                  leading: Icons.format_bold_rounded,
                  title: Text('Font Weight'),
                  value: defaultDanmakuFontWeight.toDouble(),
                  min: 1,
                  max: 9,
                  divisions: 8,
                  valueLabel: '$defaultDanmakuFontWeight',
                  onChanged: (value) => updateDanmakuFontWeight(value.toInt()),
                ),
                SettingsSliderTile(
                  leading: Icons.opacity_rounded,
                  title: Text('Danmaku Opacity'),
                  value: defaultDanmakuOpacity,
                  min: 0.1,
                  max: 1,
                  valueLabel: '${(defaultDanmakuOpacity * 100).round()}%',
                  onChanged: (value) => updateDanmakuOpacity(
                      double.parse(value.toStringAsFixed(2))),
                ),
              ],
            ),
            SettingsSection(
              tiles: [
                SettingsTile(
                  leading: Icons.settings_backup_restore_rounded,
                  onPressed: (_) => resetDanmakuSettings(),
                  title: Text('Restore Default Settings'),
                  description: Text('Reset danmaku-related settings to default'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

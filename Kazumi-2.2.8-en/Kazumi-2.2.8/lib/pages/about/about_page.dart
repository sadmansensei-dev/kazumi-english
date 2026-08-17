import 'dart:io';

import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/pages/my/my_controller.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/utils/dandan_credentials.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kazumi/utils/device.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({
    super.key,
    required this.controller,
  });

  final MyController controller;

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  final exitBehaviorTitles = <String>['Exit Kazumi', 'Minimize to Tray', 'Always Ask'];
  late dynamic defaultDanmakuArea;
  late dynamic defaultThemeMode;
  late dynamic defaultThemeColor;
  late int exitBehavior = GStorage.getSetting(SettingsKeys.exitBehavior);
  late bool autoUpdate;
  late bool checkPluginUpdateOnStartup;
  double _cacheSizeMB = -1;
  MyController get myController => widget.controller;
  final MenuController menuController = MenuController();

  @override
  void initState() {
    super.initState();
    autoUpdate = GStorage.getSetting(SettingsKeys.autoUpdate);
    checkPluginUpdateOnStartup =
        GStorage.getSetting(SettingsKeys.checkPluginUpdateOnStartup);
    _getCacheSize();
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  Future<Directory> _getCacheDir() async {
    Directory tempDir = await getTemporaryDirectory();
    return Directory('${tempDir.path}/libCachedImageData');
  }

  Future<void> _getCacheSize() async {
    Directory cacheDir = await _getCacheDir();

    if (await cacheDir.exists()) {
      int totalSizeBytes = await _getTotalSizeOfFilesInDir(cacheDir);
      double totalSizeMB = (totalSizeBytes / (1024 * 1024));

      if (mounted) {
        setState(() {
          _cacheSizeMB = totalSizeMB;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _cacheSizeMB = 0.0;
        });
      }
    }
  }

  Future<int> _getTotalSizeOfFilesInDir(final Directory directory) async {
    final List<FileSystemEntity> children = directory.listSync();
    int total = 0;

    try {
      for (final FileSystemEntity child in children) {
        if (child is File) {
          final int length = await child.length();
          total += length;
        } else if (child is Directory) {
          total += await _getTotalSizeOfFilesInDir(child);
        }
      }
    } catch (_) {}
    return total;
  }

  Future<void> _clearCache() async {
    final Directory libCacheDir = await _getCacheDir();
    await libCacheDir.delete(recursive: true);
    _getCacheSize();
  }

  void _showCacheDialog() {
    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('Cache Management'),
          content: const Text('This caches anime covers; after clearing, they will need to be re-downloaded when loading. Clear the cache?'),
          actions: [
            TextButton(
              onPressed: () {
                KazumiDialog.dismiss();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  _clearCache();
                } catch (_) {}
                KazumiDialog.dismiss();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        onBackPressed(context);
      },
      child: SettingsDetailScaffold(
        title: const Text('About'),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Open Source'),
              tiles: [
                SettingsTile(
                  leading: Icons.gavel_rounded,
                  onPressed: (_) {
                    context.pushNamed('/settings/about/license');
                  },
                  title: Text('Open Source License'),
                  description: Text('View All Open Source Licenses'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('External Link'),
              tiles: [
                SettingsTile(
                  leading: Icons.home_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.projectUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Project Homepage'),
                ),
                SettingsTile(
                  leading: Icons.code_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.sourceUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Code Repository'),
                  value: Text('Github'),
                ),
                SettingsTile(
                  leading: Icons.brush_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.iconUrl),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Icon Design'),
                  value: Text('Pixiv'),
                ),
                SettingsTile(
                  leading: Icons.menu_book_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.bangumiIndex),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Anime Index'),
                  value: Text('Bangumi'),
                ),
                SettingsTile(
                  leading: Icons.image_search_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse('https://trace.moe'),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Search Anime by Image'),
                  value: Text('trace.moe'),
                ),
                SettingsTile(
                  leading: Icons.subtitles_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.dandanIndex),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Danmaku Source'),
                  description: Text('ID: ${dandanCredentials['id']}'),
                  value: Text('DanDanPlay Open Platform'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Community'),
              tiles: [
                SettingsTile(
                  leading: Icons.send_rounded,
                  onPressed: (_) {
                    launchUrl(Uri.parse(ApiEndpoints.telegramGroup),
                        mode: LaunchMode.externalApplication);
                  },
                  title: Text('Telegram'),
                  value: Text('Tap to Join'),
                ),
              ],
            ),
            if (isDesktop()) // 之后如果有非桌面平台的新选项可以移除
              SettingsSection(
                title: Text('Default Behavior'),
                tiles: [
                  SettingsTile(
                    leading: Icons.exit_to_app_rounded,
                    onPressed: (_) {
                      if (menuController.isOpen) {
                        menuController.close();
                      } else {
                        menuController.open();
                      }
                    },
                    title: Text('When Off'),
                    value: MenuAnchor(
                      consumeOutsideTap: true,
                      controller: menuController,
                      builder: (_, __, ___) {
                        return Text(exitBehaviorTitles[exitBehavior]);
                      },
                      menuChildren: [
                        for (int i = 0; i < 3; i++)
                          MenuItemButton(
                            requestFocusOnHover: false,
                            onPressed: () {
                              exitBehavior = i;
                              GStorage.putSetting(SettingsKeys.exitBehavior, i);
                              setState(() {});
                            },
                            child: Container(
                              height: 48,
                              constraints: BoxConstraints(minWidth: 112),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  exitBehaviorTitles[i],
                                  style: TextStyle(
                                    color: i == exitBehavior
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
              title: Text('Storage & Logs'),
              tiles: [
                SettingsTile(
                  leading: Icons.receipt_long_rounded,
                  onPressed: (_) {
                    context.pushNamed('/settings/about/logs');
                  },
                  title: Text('Error Log'),
                ),
                SettingsTile(
                  leading: Icons.cleaning_services_rounded,
                  onPressed: (_) {
                    _showCacheDialog();
                  },
                  title: Text('Clear Cache'),
                  value: _cacheSizeMB == -1
                      ? Text('Calculating...')
                      : Text('${_cacheSizeMB.toStringAsFixed(2)}MB'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('App Update'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.update_rounded,
                  onToggle: (value) async {
                    autoUpdate = value ?? !autoUpdate;
                    await GStorage.putSetting(
                        SettingsKeys.autoUpdate, autoUpdate);
                    setState(() {});
                  },
                  title: Text('Check for app updates on startup'),
                  initialValue: autoUpdate,
                ),
                SettingsTile(
                  leading: Icons.system_update_rounded,
                  onPressed: (_) {
                    myController.checkUpdate();
                  },
                  title: Text('Check for App Updates'),
                  value: Text('Current version ${ApiEndpoints.version}'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('Rule Update'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.extension_rounded,
                  onToggle: (value) async {
                    checkPluginUpdateOnStartup =
                        value ?? !checkPluginUpdateOnStartup;
                    await GStorage.putSetting(
                      SettingsKeys.checkPluginUpdateOnStartup,
                      checkPluginUpdateOnStartup,
                    );
                    setState(() {});
                  },
                  title: Text('Check for rule updates on startup'),
                  initialValue: checkPluginUpdateOnStartup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

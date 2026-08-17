import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/services/sync/bangumi_sync_service.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/sync/webdav.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class WebDavSettingsPage extends StatefulWidget {
  const WebDavSettingsPage({super.key});

  @override
  State<WebDavSettingsPage> createState() => _PlayerSettingsPageState();
}

class _PlayerSettingsPageState extends State<WebDavSettingsPage> {
  late bool webDavEnable;
  late bool webDavEnableHistory;
  late bool webDavEnableCollect;
  late bool enableGitProxy;
  late bool enableBangumiProxy;
  late bool bangumiSyncEnable;

  @override
  void initState() {
    super.initState();
    webDavEnable = GStorage.getSetting(SettingsKeys.webDavEnable);
    webDavEnableHistory = GStorage.getSetting(SettingsKeys.webDavEnableHistory);
    webDavEnableCollect = GStorage.getSetting(SettingsKeys.webDavEnableCollect);
    enableGitProxy = GStorage.getSetting(SettingsKeys.enableGitProxy);
    enableBangumiProxy = GStorage.getSetting(SettingsKeys.enableBangumiProxy);
    bangumiSyncEnable = GStorage.getSetting(SettingsKeys.bangumiSyncEnable);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  Future<void> syncHistoryWithWebDav() async {
    var webDavEnable = GStorage.getSetting(SettingsKeys.webDavEnable);
    if (webDavEnable) {
      KazumiLogger().i('WebDav: manual history sync started');
      KazumiDialog.showToast(message: 'Syncing watch history');
      var webDav = WebDav();
      try {
        if (!webDav.isHistorySyncing) {
          await webDav.ping();
        }
        try {
          await webDav.syncHistory();
          KazumiLogger().i('WebDav: manual history sync completed');
          KazumiDialog.showToast(message: 'Watch history sync complete');
        } catch (e) {
          KazumiLogger().w('WebDav: manual history sync failed', error: e);
          KazumiDialog.showToast(message: 'Watch history sync failed ${e.toString()}');
        }
      } catch (e) {
        KazumiLogger().w('WebDav: manual history sync ping failed', error: e);
        KazumiDialog.showToast(message: 'WebDAV connection failed');
      }
    } else {
      KazumiDialog.showToast(message: 'WebDAV sync is not enabled or the configuration is invalid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        onBackPressed(context);
      },
      child: SettingsDetailScaffold(
        title: const Text('Sync Settings'),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Rule Repository'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.hub_rounded,
                  onToggle: (value) async {
                    enableGitProxy = value ?? !enableGitProxy;
                    await GStorage.putSetting(
                        SettingsKeys.enableGitProxy, enableGitProxy);
                    setState(() {});
                  },
                  title: Text('Rule Repository Mirror'),
                  description: Text('Use a mirror to access the rule update and management repository'),
                  initialValue: enableGitProxy,
                ),
              ],
            ),
            SettingsSection(
              title: Text('Bangumi'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.cloud_rounded,
                  onToggle: (value) async {
                    enableBangumiProxy = value ?? !enableBangumiProxy;
                    await GStorage.putSetting(
                        SettingsKeys.enableBangumiProxy, enableBangumiProxy);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  title: Text('Bangumi Mirror'),
                  description: Text('Use the local Bangumi cache backend to load popular and category rankings'),
                  initialValue: enableBangumiProxy,
                ),
                SettingsTile.switchTile(
                  leading: Icons.sync_rounded,
                  onToggle: (value) async {
                    final tBangumiEnableSync = value ?? !bangumiSyncEnable;
                    final bangumi = BangumiSyncService();
                    if (tBangumiEnableSync == true) {
                      final token =
                          GStorage.getSetting(SettingsKeys.bangumiAccessToken)
                              .trim();
                      if (token.isEmpty) {
                        KazumiDialog.showToast(
                            message: 'Please configure your Bangumi Access Token first');
                        return;
                      } else {
                        if (!bangumi.initialized) {
                          try {
                            await bangumi.init();
                          } catch (e) {
                            KazumiDialog.showToast(
                                message: "Bangumi initialization failed, please try again later");
                            return;
                          }
                        }
                      }
                    }
                    bangumiSyncEnable = tBangumiEnableSync;
                    await GStorage.putSetting(
                        SettingsKeys.bangumiSyncEnable, bangumiSyncEnable);
                    if (!mounted) {
                      return;
                    }
                    setState(() {});
                  },
                  title: Text('Bangumi Sync'),
                  description: Text('Allow automatic sync of collection/tracking status with Bangumi'),
                  initialValue: bangumiSyncEnable,
                ),
                SettingsTile(
                  leading: Icons.tune_rounded,
                  onPressed: (_) async {
                    await context.pushNamed('/settings/bangumi/');
                    bangumiSyncEnable =
                        GStorage.getSetting(SettingsKeys.bangumiSyncEnable);
                    setState(() {});
                  },
                  title: Text('Bangumi Settings'),
                ),
              ],
            ),
            SettingsSection(
              title: Text('WEBDAV'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.cloud_sync_rounded,
                  onToggle: (value) async {
                    webDavEnable = value ?? !webDavEnable;
                    if (!WebDav().initialized && webDavEnable) {
                      try {
                        await WebDav().init();
                      } catch (e) {
                        webDavEnable = false;
                        KazumiDialog.showToast(message: 'WebDAV initialization failed $e');
                      }
                    }
                    if (!webDavEnable) {
                      webDavEnableHistory = false;
                      webDavEnableCollect = false;
                      await GStorage.putSetting(
                          SettingsKeys.webDavEnableHistory, false);
                      await GStorage.putSetting(
                          SettingsKeys.webDavEnableCollect, false);
                    }
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnable, webDavEnable);
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  title: Text('WebDAV Sync'),
                  initialValue: webDavEnable,
                ),
                SettingsTile.switchTile(
                  leading: Icons.history_rounded,
                  onToggle: (value) async {
                    if (!webDavEnable) {
                      KazumiDialog.showToast(message: 'Please enable WebDAV sync first');
                      return;
                    }
                    webDavEnableHistory = value ?? !webDavEnableHistory;
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnableHistory, webDavEnableHistory);
                    setState(() {});
                  },
                  title: Text('Watch History Sync'),
                  description: Text('Allow automatic sync of watch history'),
                  initialValue: webDavEnableHistory,
                ),
                SettingsTile.switchTile(
                  leading: Icons.favorite_rounded,
                  onToggle: (value) async {
                    if (!webDavEnable) {
                      KazumiDialog.showToast(message: 'Please enable WebDAV sync first');
                      return;
                    }
                    webDavEnableCollect = value ?? !webDavEnableCollect;
                    await GStorage.putSetting(
                        SettingsKeys.webDavEnableCollect, webDavEnableCollect);
                    setState(() {});
                  },
                  title: Text('Collection Sync'),
                  description: Text('Allow WebDAV to participate in tracking-status sync'),
                  initialValue: webDavEnableCollect,
                ),
                SettingsTile(
                  leading: Icons.tune_rounded,
                  onPressed: (_) async {
                    context.pushNamed('/settings/webdav/editor');
                  },
                  title: Text('WebDAV Settings'),
                ),
                SettingsTile(
                  leading: Icons.cloud_upload_rounded,
                  trailing: const Icon(Icons.sync_rounded),
                  onPressed: (_) {
                    syncHistoryWithWebDav();
                  },
                  title: Text('Sync Watch History Now'),
                  description: Text('Two-way merge watch history with WebDAV'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

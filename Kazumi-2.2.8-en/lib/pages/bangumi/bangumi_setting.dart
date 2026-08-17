import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:flutter/material.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/modules/bangumi/sync_priority.dart';
import 'package:kazumi/services/sync/bangumi_sync_service.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:url_launcher/url_launcher.dart';

class BangumiEditorPage extends StatefulWidget {
  const BangumiEditorPage({super.key});

  @override
  State<BangumiEditorPage> createState() => _BangumiEditorPageState();
}

class _BangumiEditorPageState extends State<BangumiEditorPage> {
  final TextEditingController bangumiTokenController = TextEditingController();
  bool passwordVisible = false;
  bool isVerifying = false;
  late bool bangumiImmediateSyncToastEnable;
  late int syncPriority;
  bool syncCollectiblesing = false;
  final MenuController syncPriorityMenuController = MenuController();

  @override
  void initState() {
    super.initState();
    bangumiTokenController.text =
        GStorage.getSetting(SettingsKeys.bangumiAccessToken);
    bangumiImmediateSyncToastEnable =
        GStorage.getSetting(SettingsKeys.bangumiImmediateSyncToastEnable);
    syncPriority = GStorage.getSetting(SettingsKeys.bangumiSyncPriority);
  }

  @override
  void dispose() {
    bangumiTokenController.dispose();
    super.dispose();
  }

  Future<void> updateSyncPriority(int value) async {
    await GStorage.putSetting(SettingsKeys.bangumiSyncPriority, value);
    if (!mounted) return;
    setState(() {
      syncPriority = value;
    });
  }

  Future<void> syncWithProgress() async {
    final syncEnable = GStorage.getSetting(SettingsKeys.bangumiSyncEnable);
    if (!syncEnable) {
      KazumiDialog.showToast(message: 'Please enable Bangumi sync first');
      return;
    }

    final progressDialogKey = GlobalKey<_BangumiSyncProgressDialogState>();

    try {
      setState(() {
        syncCollectiblesing = true;
      });

      KazumiDialog.show(
        clickMaskDismiss: false,
        builder: (context) =>
            _BangumiSyncProgressDialog(key: progressDialogKey),
      );

      final bangumi = BangumiSyncService();
      await bangumi.ping();
      await bangumi.syncCollectibles(
        onProgress: (message, current, total) {
          progressDialogKey.currentState?.update(
            total > 0 ? '$message ($current/$total)' : message,
            total > 0 ? (current / total).clamp(0.0, 1.0).toDouble() : null,
          );
        },
      );
    } catch (e) {
      KazumiDialog.showToast(message: 'Bangumi sync failed: $e');
    } finally {
      if (KazumiDialog.observer.hasKazumiDialog) {
        KazumiDialog.dismiss();
      }
      if (mounted) {
        setState(() {
          syncCollectiblesing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !syncCollectiblesing,
      child: Scaffold(
        appBar: const SysAppBar(title: Text('Bangumi Settings')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SizedBox(
              width: (MediaQuery.of(context).size.width > 1000) ? 1000 : null,
              child: Column(
                children: [
                  TextField(
                    controller: bangumiTokenController,
                    obscureText: !passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Bangumi Access Token',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            passwordVisible = !passwordVisible;
                          });
                        },
                        icon: Icon(passwordVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SettingsSection(
                    title: Text('Sync Options'),
                    margin: EdgeInsetsDirectional.zero,
                    tiles: [
                      SettingsTile.switchTile(
                        leading: Icons.notifications_active_rounded,
                        onToggle: (value) async {
                          bangumiImmediateSyncToastEnable =
                              value ?? !bangumiImmediateSyncToastEnable;
                          await GStorage.putSetting(
                            SettingsKeys.bangumiImmediateSyncToastEnable,
                            bangumiImmediateSyncToastEnable,
                          );
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        title: Text('Instant Sync Notice'),
                        description: Text('Show a prompt when tapping the track button triggers instant sync'),
                        initialValue: bangumiImmediateSyncToastEnable,
                      ),
                      SettingsTile(
                        leading: Icons.rule_rounded,
                        onPressed: (_) async {
                          if (syncPriorityMenuController.isOpen) {
                            syncPriorityMenuController.close();
                          } else {
                            syncPriorityMenuController.open();
                          }
                        },
                        title: Text('Sync Priority'),
                        description: Text('Which status to prefer when local and Bangumi status differ'),
                        value: MenuAnchor(
                            consumeOutsideTap: true,
                            controller: syncPriorityMenuController,
                            builder: (context, controller, child) => Text(
                                BangumiSyncPriority.fromValue(syncPriority)
                                    .label),
                            menuChildren: [
                              for (final entry in BangumiSyncPriority.values)
                                MenuItemButton(
                                    requestFocusOnHover: false,
                                    onPressed: () =>
                                        updateSyncPriority(entry.value),
                                    child: Container(
                                        height: 48,
                                        constraints:
                                            BoxConstraints(minWidth: 112),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            entry.label,
                                            style: TextStyle(
                                              color: entry.value == syncPriority
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : null,
                                            ),
                                          ),
                                        )))
                            ]),
                      ),
                      SettingsTile(
                        leading: Icons.cloud_sync_rounded,
                        trailing: syncCollectiblesing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded),
                        onPressed: (_) async {
                          await syncWithProgress();
                        },
                        title: Text("Sync Status Now"),
                        description: Text('Items with inconsistent sync status, or that exist only locally or only remotely'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final url =
                          Uri.parse('https://next.bgm.tv/demo/access-token');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        KazumiDialog.showToast(message: 'Unable to open link');
                      }
                    },
                    child: Text(
                      'You can click here to go to Bangumi and generate an Access Token',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: isVerifying
              ? null
              : () async {
                  final token = bangumiTokenController.text.trim();
                  final bool bangumiSyncEnable =
                      GStorage.getSetting(SettingsKeys.bangumiSyncEnable);

                  if (token.isEmpty && bangumiSyncEnable) {
                    KazumiDialog.showToast(message: 'Access Token cannot be empty');
                    return;
                  }
                  setState(() {
                    isVerifying = true;
                  });
                  await GStorage.putSetting(
                      SettingsKeys.bangumiAccessToken, token);
                  final bangumi = BangumiSyncService();

                  if (token.isEmpty) {
                    bangumi.reset();
                    KazumiDialog.showToast(message: 'Bangumi Token is empty, please check');
                    if (!mounted) return;
                    setState(() {
                      isVerifying = false;
                    });
                    return;
                  }

                  KazumiDialog.showToast(message: 'Testing Bangumi Token...');
                  try {
                    await bangumi.init();
                  } catch (e) {
                    KazumiDialog.showToast(message: 'Verification failed: ${e.toString()}');
                    await GStorage.putSetting(
                        SettingsKeys.bangumiSyncEnable, false);
                    if (!mounted) return;
                    setState(() {
                      isVerifying = false;
                    });
                    return;
                  }

                  KazumiDialog.showToast(
                      message: 'Test successful, username: ${bangumi.username}');
                  if (!mounted) return;
                  setState(() {
                    isVerifying = false;
                  });
                },
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
}

class _BangumiSyncProgressDialog extends StatefulWidget {
  const _BangumiSyncProgressDialog({super.key});

  @override
  State<_BangumiSyncProgressDialog> createState() =>
      _BangumiSyncProgressDialogState();
}

class _BangumiSyncProgressDialogState
    extends State<_BangumiSyncProgressDialog> {
  String _progressText = 'Preparing to sync Bangumi status...';
  double? _progressValue;

  void update(String text, double? value) {
    if (!mounted) return;
    setState(() {
      _progressText = text;
      _progressValue = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bangumi sync in progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(_progressText),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progressValue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

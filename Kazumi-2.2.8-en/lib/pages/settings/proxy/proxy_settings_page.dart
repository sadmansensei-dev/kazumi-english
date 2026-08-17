import 'package:flutter/material.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/settings/settings_detail_scaffold.dart';
import 'package:kazumi/services/storage/storage.dart';
import 'package:kazumi/services/network/proxy_manager.dart';
import 'package:kazumi/bean/settings/settings_list.dart';

class ProxySettingsPage extends StatefulWidget {
  const ProxySettingsPage({super.key});

  @override
  State<ProxySettingsPage> createState() => _ProxySettingsPageState();
}

class _ProxySettingsPageState extends State<ProxySettingsPage> {
  late bool proxyEnable;

  @override
  void initState() {
    super.initState();
    proxyEnable = GStorage.getSetting(SettingsKeys.proxyEnable);
  }

  void onBackPressed(BuildContext context) {
    if (KazumiDialog.observer.hasKazumiDialog) {
      KazumiDialog.dismiss();
      return;
    }
  }

  Future<void> updateProxyEnable(bool value) async {
    if (value) {
      final proxyConfigured = GStorage.getSetting(SettingsKeys.proxyConfigured);
      if (!proxyConfigured) {
        KazumiDialog.showToast(message: 'Please complete the test in the proxy configuration first');
        return;
      }
      await GStorage.putSetting(SettingsKeys.proxyEnable, true);
      ProxyManager.applyProxy();
    } else {
      await GStorage.putSetting(SettingsKeys.proxyEnable, false);
      ProxyManager.clearProxy();
    }
    setState(() {
      proxyEnable = value;
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
        title: const Text('Proxy Settings'),
        body: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Proxy'),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icons.vpn_key_rounded,
                  onToggle: (value) async {
                    await updateProxyEnable(value ?? !proxyEnable);
                  },
                  title: Text('Enable Proxy'),
                  description: Text('When enabled, network requests will go through the proxy server'),
                  initialValue: proxyEnable,
                ),
                SettingsTile(
                  leading: Icons.tune_rounded,
                  onPressed: (_) async {
                    await context.pushNamed('/settings/proxy/editor');
                    setState(() {
                      proxyEnable =
                          GStorage.getSetting(SettingsKeys.proxyEnable);
                    });
                  },
                  title: Text('Proxy Configuration'),
                  description: Text('Configure the proxy server address and authentication info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

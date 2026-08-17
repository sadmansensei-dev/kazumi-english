import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/pages/plugin_editor/plugin_editor_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_shop_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_test_page.dart';
import 'package:kazumi/pages/plugin_editor/plugin_view_page.dart';
import 'package:kazumi/pages/route_error_page.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

final pluginModule = createModule(
  path: '/plugin',
  register: (c) {
    c
      ..route(
        '/',
        child: (context, state) => PluginViewPage(
          controller: inject<PluginsController>(),
        ),
      )
      ..route(
        '/shop',
        child: (context, state) => PluginShopPage(
          controller: inject<PluginsController>(),
        ),
      )
      ..route(
        '/test',
        child: (context, state) {
          final plugin = state.arguments;
          if (plugin is! Plugin) {
            return const RouteErrorPage(message: 'Invalid rule test parameters, please go back and try again.');
          }
          return PluginTestPage(plugin: plugin);
        },
      )
      ..route(
        '/editor',
        child: (context, state) {
          final plugin = state.arguments;
          if (plugin is! Plugin) {
            return const RouteErrorPage(message: 'Invalid rule edit parameters, please go back and try again.');
          }
          return PluginEditorPage(
            plugin: plugin,
            controller: inject<PluginsController>(),
          );
        },
      );
  },
);

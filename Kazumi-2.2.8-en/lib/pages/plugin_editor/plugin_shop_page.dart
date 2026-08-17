import 'package:flutter/material.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/pages/plugin_editor/plugin_catalog_view.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

class PluginShopPage extends StatefulWidget {
  const PluginShopPage({
    super.key,
    required this.controller,
  });

  final PluginsController controller;

  @override
  State<PluginShopPage> createState() => _PluginShopPageState();
}

class _PluginShopPageState extends State<PluginShopPage> {
  final catalogKey = GlobalKey<PluginCatalogViewState>();
  bool sortByName = false;

  void _toggleSort() {
    setState(() {
      sortByName = !sortByName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SysAppBar(
        title: const Text('Rule Repository'),
        actions: [
          IconButton(
              onPressed: _toggleSort,
              tooltip: sortByName ? 'Sort by Name' : 'Sort by Update Time',
              icon: Icon(sortByName ? Icons.sort_by_alpha : Icons.access_time)),
          IconButton(
              onPressed: () => catalogKey.currentState?.refresh(),
              tooltip: 'Refresh Rule List',
              icon: const Icon(Icons.refresh))
        ],
      ),
      body: PluginCatalogView(
        key: catalogKey,
        controller: widget.controller,
        sort:
            sortByName ? PluginCatalogSort.name : PluginCatalogSort.lastUpdate,
        errorMessage: 'Huh (⊙.⊙) Unable to access the rule repository',
      ),
    );
  }
}

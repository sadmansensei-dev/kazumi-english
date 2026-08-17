import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/plugins/plugins_controller.dart';

Future<void> updateAllPluginsWithFeedback(
  PluginsController controller, {
  required bool ensureCatalog,
}) async {
  KazumiDialog.showLoading(msg: 'Updating');
  try {
    final result = await controller.tryUpdateAllPlugin(
      ensureCatalog: ensureCatalog,
    );
    KazumiDialog.dismiss();
    KazumiDialog.showToast(message: _batchUpdateMessage(result));
  } catch (_) {
    KazumiDialog.dismiss();
    KazumiDialog.showToast(message: 'Failed to update rule');
  }
}

Future<PluginUpdateResult> updatePluginWithFeedback(
  PluginsController controller,
  String name, {
  required bool installing,
}) async {
  KazumiDialog.showToast(message: installing ? 'Importing' : 'Updating');
  late final PluginUpdateResult result;
  try {
    result = await controller.tryUpdatePluginByName(name);
  } catch (_) {
    KazumiDialog.showToast(message: 'Failed to save rule');
    return PluginUpdateResult.failed;
  }
  final message = switch (result) {
    PluginUpdateResult.updated => installing ? 'Import Successful' : 'Update Successful',
    PluginUpdateResult.requiresNewerClient => 'This rule requires a newer client version',
    PluginUpdateResult.failed => installing ? 'Failed to import rule' : 'Failed to update rule',
    PluginUpdateResult.notNewer => 'Remote rule version is not newer than local, update skipped',
  };
  KazumiDialog.showToast(message: message);
  return result;
}

String _batchUpdateMessage(PluginBatchUpdateResult result) {
  if (result.hasNoCandidates) {
    return 'No rules to update';
  }
  if (result.failed == 0 &&
      result.requiresNewerClient == 0 &&
      result.notNewer == 0) {
    return '${result.updated} updated successfully';
  }

  final parts = <String>['${result.updated} succeeded'];
  if (result.requiresNewerClient > 0) {
    parts.add('${result.requiresNewerClient} incompatible');
  }
  if (result.notNewer > 0) {
    parts.add('${result.notNewer} skipped');
  }
  if (result.failed > 0) {
    parts.add('${result.failed} failed');
  }
  return 'Update complete: ${parts.join(', ')}';
}

import 'dart:io';

import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/services/player/external_player.dart';

class ExternalPlaybackLauncher {
  final String Function() videoUrl;
  final String Function() referer;

  ExternalPlaybackLauncher({
    required this.videoUrl,
    required this.referer,
  });

  Future<void> launch() async {
    final currentVideoUrl = videoUrl();
    final currentReferer = referer();
    if ((Platform.isAndroid || Platform.isWindows) && currentReferer.isEmpty) {
      if (await ExternalPlayer.launchUrlWithMime(
          currentVideoUrl, 'video/mp4')) {
        KazumiDialog.dismiss();
        KazumiDialog.showToast(
          message: 'Try launching external player',
        );
      } else {
        KazumiDialog.showToast(
          message: 'Failed to launch external player',
        );
      }
    } else if (Platform.isMacOS || Platform.isIOS) {
      if (await ExternalPlayer.launchUrlWithReferer(
          currentVideoUrl, currentReferer)) {
        KazumiDialog.dismiss();
        KazumiDialog.showToast(
          message: 'Try launching external player',
        );
      } else {
        KazumiDialog.showToast(
          message: 'Failed to launch external player',
        );
      }
    } else if (Platform.isLinux && currentReferer.isEmpty) {
      KazumiDialog.dismiss();
      final result =
          await ExternalPlayer.launchLinuxDesktopPlayer(currentVideoUrl);
      switch (result) {
        case LinuxExternalPlayerResult.launched:
          KazumiDialog.showToast(message: 'Try launching external player');
        case LinuxExternalPlayerResult.cancelled:
          break;
        case LinuxExternalPlayerResult.unavailable:
          KazumiDialog.showToast(message: 'System app picker is unavailable');
        case LinuxExternalPlayerResult.failed:
          KazumiDialog.showToast(message: 'Failed to launch external player');
      }
    } else {
      if (currentReferer.isEmpty) {
        KazumiDialog.showToast(
          message: 'This device is not yet supported',
        );
      } else {
        KazumiDialog.showToast(
          message: 'This rule is not yet supported',
        );
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/widget/empty_state_widget.dart';
import 'package:kazumi/modules/download/download_module.dart';
import 'package:kazumi/modules/bangumi/bangumi_item.dart';
import 'package:kazumi/pages/download/download_controller.dart';
import 'package:kazumi/pages/download/download_widgets.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/utils/format.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({
    super.key,
    required this.controller,
  });

  final DownloadController controller;

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  DownloadController get downloadController => widget.controller;

  /// Expansion state per record key. Kept outside the record snapshots
  /// because the controller replaces them on every refresh tick.
  final Map<String, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    downloadController.refreshRecords();
  }

  bool _isExpanded(String recordKey, DownloadRecord record) {
    return _expanded.putIfAbsent(
      recordKey,
      () => record.episodes.values
          .any((e) => e.status != DownloadStatus.completed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SysAppBar(title: Text('Download Manager')),
      body: Observer(builder: (context) {
        final recordKeys = downloadController.recordKeys.toList();
        // Drop expansion state for deleted records, so a re-downloaded
        // bangumi gets a fresh default instead of a stale cached one.
        _expanded.removeWhere((key, _) => !recordKeys.contains(key));
        if (recordKeys.isEmpty) {
          return const Center(
            child: GeneralEmptyState(
              icon: Icons.download_rounded,
              title: 'No downloads yet',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: recordKeys.length,
          itemBuilder: (context, index) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: _buildRecordCard(recordKeys[index]),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildRecordCard(String recordKey) {
    return Observer(builder: (context) {
      final record = downloadController.getRecordSnapshot(recordKey);
      if (record == null) {
        return const SizedBox.shrink();
      }

      var totalSpeed = 0.0;
      for (final e in record.episodes.values) {
        if (e.status == DownloadStatus.downloading) {
          totalSpeed += downloadController.getSpeed(
            record.bangumiId,
            record.pluginName,
            e.episodeNumber,
          );
        }
      }
      final expanded = _isExpanded(recordKey, record);

      return DownloadRecordCard(
        record: record,
        expanded: expanded,
        onToggle: () {
          setState(() => _expanded[recordKey] = !expanded);
        },
        onResumeAll: () {
          downloadController.resumeAllDownloads(
            record.bangumiId,
            record.pluginName,
          );
          KazumiDialog.showToast(message: 'Resumed downloading');
        },
        onDeleteAll: () => _confirmDeleteRecord(record),
        totalSpeed: totalSpeed,
        episodeTileBuilder: () {
          final episodes = record.episodes.values.toList()
            ..sort((a, b) => a.episodeNumber.compareTo(b.episodeNumber));
          return episodes.map((ep) => _buildEpisodeTile(record, ep)).toList();
        },
      );
    });
  }

  Widget _buildEpisodeTile(DownloadRecord record, DownloadEpisode episode) {
    return DownloadEpisodeTile(
      episode: episode,
      statusText: _getStatusText(record, episode),
      actions: _getActionButtons(record, episode),
      onPlay: episode.status == DownloadStatus.completed
          ? () => _playEpisode(record, episode)
          : null,
    );
  }

  String _getStatusText(DownloadRecord record, DownloadEpisode episode) {
    switch (episode.status) {
      case DownloadStatus.completed:
        return 'Completed · ${formatBytes(episode.totalBytes)}';
      case DownloadStatus.downloading:
        final speed = downloadController.getSpeed(
          record.bangumiId,
          record.pluginName,
          episode.episodeNumber,
        );
        final speedText = speed > 0 ? ' · ${formatSpeed(speed)}' : '';
        return '${(episode.progressPercent * 100).toStringAsFixed(0)}% · '
            '${episode.downloadedSegments}/${episode.totalSegments} segments$speedText';
      case DownloadStatus.failed:
        return episode.errorMessage.isNotEmpty ? episode.errorMessage : 'Download Failed';
      case DownloadStatus.paused:
        return 'Paused · ${(episode.progressPercent * 100).toStringAsFixed(0)}%';
      case DownloadStatus.pending:
        return 'Queued';
      case DownloadStatus.resolving:
        return 'Parsing video source';
      default:
        return '';
    }
  }

  List<Widget> _getActionButtons(
      DownloadRecord record, DownloadEpisode episode) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttons = <Widget>[];

    switch (episode.status) {
      case DownloadStatus.completed:
        buttons.add(IconButton(
          icon: Icon(Icons.play_circle_outline,
              size: 20, color: colorScheme.primary),
          onPressed: () => _playEpisode(record, episode),
          tooltip: 'Play',
          visualDensity: VisualDensity.compact,
        ));
        break;
      case DownloadStatus.downloading:
        buttons.add(IconButton(
          icon: const Icon(Icons.pause_rounded, size: 20),
          onPressed: () => downloadController.pauseDownload(
            record.bangumiId,
            record.pluginName,
            episode.episodeNumber,
          ),
          tooltip: 'Pause',
          visualDensity: VisualDensity.compact,
        ));
        break;
      case DownloadStatus.paused:
        buttons.add(IconButton(
          icon: const Icon(Icons.play_arrow_rounded, size: 20),
          onPressed: () => downloadController.retryDownload(
            bangumiId: record.bangumiId,
            pluginName: record.pluginName,
            episodeNumber: episode.episodeNumber,
          ),
          tooltip: 'Continue',
          visualDensity: VisualDensity.compact,
        ));
        break;
      case DownloadStatus.failed:
        buttons.add(IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          onPressed: () => downloadController.retryDownload(
            bangumiId: record.bangumiId,
            pluginName: record.pluginName,
            episodeNumber: episode.episodeNumber,
          ),
          tooltip: 'Retry',
          visualDensity: VisualDensity.compact,
        ));
        break;
      case DownloadStatus.pending:
        buttons.add(IconButton(
          icon: Icon(Icons.priority_high,
              size: 20, color: colorScheme.primary),
          onPressed: () {
            downloadController.priorityDownload(
              bangumiId: record.bangumiId,
              pluginName: record.pluginName,
              episodeNumber: episode.episodeNumber,
            );
            KazumiDialog.showToast(message: 'Moved to front of download queue');
          },
          tooltip: 'Priority Download',
          visualDensity: VisualDensity.compact,
        ));
        break;
      default:
        break;
    }

    buttons.add(IconButton(
      icon: Icon(Icons.delete_outline,
          size: 20, color: colorScheme.onSurfaceVariant),
      onPressed: () => _confirmDeleteEpisode(record, episode),
      tooltip: 'Delete',
      visualDensity: VisualDensity.compact,
    ));

    return buttons;
  }

  void _playEpisode(DownloadRecord record, DownloadEpisode episode) {
    final localPath = downloadController.getLocalVideoPath(
      record.bangumiId,
      record.pluginName,
      episode.episodeNumber,
    );
    if (localPath == null) {
      KazumiDialog.showToast(message: 'Local file does not exist');
      return;
    }

    final bangumiItem = BangumiItem(
      id: record.bangumiId,
      type: 2,
      name: record.bangumiName,
      nameCn: record.bangumiName,
      summary: '',
      airDate: '',
      airWeekday: 0,
      rank: 0,
      images: {'large': record.bangumiCover},
      tags: [],
      alias: [],
      ratingScore: 0.0,
      votes: 0,
      votesCount: [],
      info: '',
    );

    final downloadedEpisodes = downloadController.getCompletedEpisodes(
      record.bangumiId,
      record.pluginName,
    );

    context.pushNamed(
      '/video/',
      arguments: OfflineVideoPlaybackArgs(
        bangumiItem: bangumiItem,
        pluginName: record.pluginName,
        episodeNumber: episode.episodeNumber,
        road: episode.road,
        downloadedEpisodes: downloadedEpisodes,
      ),
    );
  }

  void _confirmDeleteEpisode(DownloadRecord record, DownloadEpisode episode) {
    KazumiDialog.show(
      builder: (context) => AlertDialog(
        title: const Text('Delete Download'),
        content: Text(
            'Delete the downloaded file for "${episode.episodeName.isNotEmpty ? episode.episodeName : 'Episode ${episode.episodeNumber}'}"?'),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              downloadController.deleteEpisode(
                record.bangumiId,
                record.pluginName,
                episode.episodeNumber,
              );
              KazumiDialog.dismiss();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRecord(DownloadRecord record) {
    KazumiDialog.show(
      builder: (context) => AlertDialog(
        title: const Text('Delete All Downloads'),
        content: Text('Delete all downloaded files for "${record.bangumiName}"?'),
        actions: [
          TextButton(
            onPressed: () => KazumiDialog.dismiss(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          TextButton(
            onPressed: () {
              downloadController.deleteRecord(
                record.bangumiId,
                record.pluginName,
              );
              KazumiDialog.dismiss();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

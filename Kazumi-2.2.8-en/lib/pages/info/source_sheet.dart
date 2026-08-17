import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_modular/flutter_modular.dart';
// Only the reaction API: mobx also exports a Listenable, which collides with
// the Flutter one used further down this file.
import 'package:mobx/mobx.dart' show reaction, ReactionDisposer;
import 'package:kazumi/pages/info/info_controller.dart';
import 'package:kazumi/services/logging/logger.dart';
import 'package:kazumi/bean/dialog/dialog_helper.dart';
import 'package:kazumi/bean/dialog/material_bottom_sheet.dart';
import 'package:kazumi/bean/settings/settings_list.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/modules/search/plugin_search_module.dart';
import 'package:kazumi/pages/video/video_playback_args.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart'
    show RuleCancelToken;
import 'package:url_launcher/url_launcher.dart';
import 'package:kazumi/services/plugin/plugin_search_service.dart';
import 'package:kazumi/pages/collect/collect_controller.dart';
import 'dart:async';
import 'dart:convert';
import 'package:kazumi/services/plugin/captcha_verification_service.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/utils/device.dart';

class SourceSheet extends StatefulWidget {
  const SourceSheet({
    super.key,
    required this.infoController,
  });

  final InfoController infoController;

  @override
  State<SourceSheet> createState() => _SourceSheetState();
}

class _SourceSheetState extends State<SourceSheet> {
  final CollectController collectController = inject<CollectController>();
  final PluginsController pluginsController = inject<PluginsController>();
  late String keyword;

  /// Plugin name whose results are expanded, or null for none.
  String? expandedSource;
  ReactionDisposer? autoExpandDisposer;

  /// Concurrent plugin search service.
  PluginSearchService? pluginSearchService;

  /// Captcha verification service (created on demand)
  CaptchaVerificationService? _captchaVerificationService;

  /// Timeout timer waiting for captcha verification result
  Timer? _captchaVerifyTimer;

  @override
  void initState() {
    keyword = widget.infoController.bangumiItem.nameCn == ''
        ? widget.infoController.bangumiItem.name
        : widget.infoController.bangumiItem.nameCn;
    pluginSearchService = PluginSearchService(
      infoController: widget.infoController,
      pluginsController: pluginsController,
    );
    pluginSearchService?.queryAllSource(keyword);
    // One shot: whichever source reports results first opens, and from then on
    // the open card only moves when tapped.
    autoExpandDisposer = reaction<String?>(
      (_) => firstSourceWithResults(),
      (name) {
        if (name == null || expandedSource != null) return;
        setState(() => expandedSource = name);
        stopAutoExpand();
      },
    );
    super.initState();
  }

  void stopAutoExpand() {
    autoExpandDisposer?.call();
    autoExpandDisposer = null;
  }

  @override
  void dispose() {
    stopAutoExpand();
    pluginSearchService?.cancel();
    pluginSearchService = null;
    _captchaVerificationService?.dispose();
    _captchaVerificationService = null;
    _captchaVerifyTimer?.cancel();
    _captchaVerifyTimer = null;
    super.dispose();
  }

  /// After verification the webview already shows the real result page;
  /// prefer publishing the harvested HTML directly and only fall back to a
  /// delayed re-search when it does not parse.
  void _showVerifiedResult(Plugin plugin, String pageHtml) {
    final harvested = pluginSearchService?.applyHarvestedSearchResult(
          plugin.name,
          pageHtml,
        ) ??
        false;
    if (harvested) {
      KazumiDialog.showToast(message: 'Verification Successful');
      return;
    }
    // show a 3s countdown progress dialog before re-querying,
    // to avoid triggering rate limits immediately after verification.
    KazumiDialog.showTimedSuccessDialog(
      title: 'Verification Successful',
      message: 'Re-searching shortly',
      onComplete: () => pluginSearchService?.querySource(keyword, plugin.name),
    );
  }

  void showAntiCrawlerDialog(Plugin plugin) {
    switch (plugin.antiCrawlerConfig.captchaType) {
      case CaptchaType.customJavaScript:
        showCustomScriptDialog(plugin);
        break;
      case CaptchaType.autoClickButton:
        showButtonClickDialog(plugin);
        break;
      default:
        showCaptchaDialog(plugin);
    }
  }

  void showCaptchaDialog(Plugin plugin) {
    /// flag whether verification has passed, used to distinguish normal dismissal from cancellation in onDismiss
    bool verified = false;

    /// Set once the webview reports the captcha gone. The timeout below only
    /// guards "verification was never detected", so it keys off this rather
    /// than [verified], which lands seconds later when the harvest finishes.
    bool finalizing = false;

    _captchaVerificationService?.dispose();
    _captchaVerificationService = CaptchaVerificationService();

    final searchUrl = plugin.searchURL
        .replaceAll('@keyword', Uri.encodeQueryComponent(keyword));

    _captchaVerificationService!.loadForCaptcha(
      searchUrl,
      plugin.antiCrawlerConfig.captchaImage,
      inputXpath: plugin.antiCrawlerConfig.captchaInput,
    );

    Future<void> submitCaptcha(String captchaCode) async {
      await _captchaVerificationService?.submitCaptcha(
        captchaCode: captchaCode.trim(),
        inputXpath: plugin.antiCrawlerConfig.captchaInput,
        buttonXpath: plugin.antiCrawlerConfig.captchaButton,
        pluginName: plugin.name,
        // Verification is already confirmed here; the harvest that follows
        // takes seconds, so retire the timeout now rather than in onVerified.
        onFinalizing: () {
          finalizing = true;
          _captchaVerifyTimer?.cancel();
          _captchaVerifyTimer = null;
        },
        onVerified: (pageHtml) {
          verified = true;
          KazumiDialog.dismiss();
          _showVerifiedResult(plugin, pageHtml);
        },
      );
      // submitCaptcha completes after the JS button click is fired.
      // Start the 8-second timeout only NOW, waiting for the webview to
      // detect the captcha disappearing.
      if (!finalizing) {
        _captchaVerifyTimer?.cancel();
        _captchaVerifyTimer = Timer(const Duration(seconds: 8), () {
          if (!finalizing) {
            KazumiDialog.dismiss();
          }
        });
      }
    }

    KazumiDialog.show(
      onDismiss: () async {
        _captchaVerifyTimer?.cancel();
        _captchaVerifyTimer = null;
        // Capture the current service instance locally before any await.
        // Without this, an async gap could allow _captchaVerificationService to be
        // replaced (or nulled by _SourceSheetState.dispose()), causing the
        // closure to dispose the wrong/already-disposed instance.
        final captchaService = _captchaVerificationService;
        _captchaVerificationService = null;
        if (!verified) {
          await captchaService?.cancelAndSave(plugin.name);
          captchaService?.dispose();
          pluginSearchService?.querySource(keyword, plugin.name);
        } else {
          captchaService?.dispose();
        }
      },
      builder: (context) => _CaptchaDialog(
        pluginName: plugin.name,
        captchaImageStream: _captchaVerificationService!.onCaptchaImageUrl,
        onSubmit: submitCaptcha,
      ),
    );
  }

  void showButtonClickDialog(Plugin plugin) {
    showAutomatedVerifyDialog(
      plugin,
      statusText: '${plugin.name} is completing verification automatically, please wait',
      detailText: 'Verification button detected and clicked, waiting for verification…',
      startVerification: (captchaService, searchUrl, onVerified) {
        return captchaService.loadForButtonClick(
          url: searchUrl,
          buttonXpath: plugin.antiCrawlerConfig.captchaButton,
          pluginName: plugin.name,
          onVerified: onVerified,
        );
      },
    );
  }

  void showCustomScriptDialog(Plugin plugin) {
    showAutomatedVerifyDialog(
      plugin,
      statusText: '${plugin.name} is running the verification script, please wait',
      detailText: 'Verification page loaded and custom script executed, waiting for verification…',
      startVerification: (captchaService, searchUrl, onVerified) {
        return captchaService.loadForCustomScript(
          url: searchUrl,
          script: plugin.antiCrawlerConfig.captchaScript,
          pluginName: plugin.name,
          onVerified: onVerified,
        );
      },
    );
  }

  void showAutomatedVerifyDialog(
    Plugin plugin, {
    required String statusText,
    required String detailText,
    required Future<void> Function(
      CaptchaVerificationService captchaService,
      String searchUrl,
      void Function(String pageHtml) onVerified,
    ) startVerification,
  }) {
    bool verified = false;

    _captchaVerificationService?.dispose();
    _captchaVerificationService = CaptchaVerificationService();

    final captchaService = _captchaVerificationService!;
    final searchUrl = plugin.searchURL
        .replaceAll('@keyword', Uri.encodeQueryComponent(keyword));

    void onVerified(String pageHtml) {
      verified = true;
      KazumiDialog.dismiss();
      _showVerifiedResult(plugin, pageHtml);
    }

    unawaited(startVerification(captchaService, searchUrl, onVerified));

    KazumiDialog.show(
      onDismiss: () async {
        final captchaService = _captchaVerificationService;
        _captchaVerificationService = null;
        if (verified) {
          captchaService?.dispose();
        } else {
          await captchaService?.cancelAndSave(plugin.name);
          captchaService?.dispose();
          pluginSearchService?.querySource(keyword, plugin.name);
        }
      },
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Auto-verifying',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  detailText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => KazumiDialog.dismiss(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A plugin can publish more than one response: an alias search adds to what
  /// the first pass found.
  List<SearchItem> resultsFor(String pluginName) {
    final results = <SearchItem>[];
    for (final response in widget.infoController.pluginSearchResponseList) {
      if (response.pluginName == pluginName) {
        results.addAll(response.data);
      }
    }
    return results;
  }

  void openInBrowser(Plugin plugin) {
    final targetUrl = plugin.usesApiSearch
        ? plugin.baseUrl
        : plugin.searchURL.replaceFirst(
            '@keyword',
            Uri.encodeQueryComponent(keyword),
          );
    launchUrl(Uri.parse(targetUrl), mode: LaunchMode.externalApplication);
  }

  Future<void> openSearchItem(Plugin plugin, SearchItem searchItem) async {
    final cancelToken = RuleCancelToken();
    KazumiDialog.showLoading(
      msg: 'Fetching',
      barrierDismissible: isDesktop(),
      onDismiss: cancelToken.cancel,
    );
    try {
      final roads = await plugin.queryChapterRoads(
        searchItem.src,
        cancelToken: cancelToken,
      );
      if (roads.isEmpty) {
        throw ChapterErrorException(plugin.name);
      }
      KazumiDialog.dismiss();
      if (!mounted) return;
      context.pushNamed(
        '/video/',
        arguments: OnlineVideoPlaybackArgs(
          bangumiItem: widget.infoController.bangumiItem,
          plugin: plugin,
          title: searchItem.name,
          src: searchItem.src,
          roads: roads,
        ),
      );
    } catch (_) {
      KazumiLogger()
          .w("PluginSearchService: failed to query video playlist");
      KazumiDialog.dismiss();
    }
  }

  /// One source, collapsed to a row until opened. The row is both the picker
  /// and its own heading, so no separate strip of source buttons is needed.
  /// A source that came back empty opens onto its recovery actions instead of
  /// results, and only one source is open at a time.
  Widget buildSourceCard(Plugin plugin, List<SearchItem> results, bool open) {
    final searching = widget.infoController.pluginSearchStatus[plugin.name] ==
        PluginSearchStatus.pending;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: SettingsSplitGroup(
          children: [
            buildSourceRow(plugin, results, searching, open),
            if (open && !searching) ...[
              for (final searchItem in results)
                buildResultRow(plugin, searchItem),
              // Buttons under a result list get hit by thumbs reaching for the
              // last row, so with results they live in the header menu.
              if (results.isEmpty) buildActionsRow(plugin),
            ],
          ],
        ),
      ),
    );
  }

  /// How many titles a source found, or why it found none. Status rides in
  /// this trailing text rather than a leading icon: rows whose siblings lack
  /// one end up with misaligned names.
  ({String text, Color? color}) sourceSummary(
      Plugin plugin, List<SearchItem> results, bool searching) {
    if (searching) return (text: 'Searching', color: null);
    if (results.isNotEmpty) return (text: '${results.length} result(s)', color: null);
    final error = Theme.of(context).colorScheme.error;
    return switch (widget.infoController.pluginSearchStatus[plugin.name]) {
      PluginSearchStatus.error => (text: 'Search Failed', color: error),
      PluginSearchStatus.captcha => (text: 'Verification Required', color: error),
      _ => (text: 'No Results', color: null),
    };
  }

  /// The open source's row is inert: exactly one source is open at a time, so
  /// tapping the open one has nothing to do, and a no-op there means a thumb
  /// overshooting the first result cannot throw the whole list away.
  Widget buildSourceRow(
      Plugin plugin, List<SearchItem> results, bool searching, bool open) {
    // A Builder so the row's context sits below the group's press scope.
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final summary = sourceSummary(plugin, results, searching);
        final hasMenu = open && results.isNotEmpty;
        final row = Padding(
          // Both branches land on 56dp, matching a result row: the menu's
          // IconButton is 48dp on its own.
          padding: hasMenu
              ? const EdgeInsets.fromLTRB(18, 4, 4, 4)
              : const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  plugin.name,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              Text(
                summary.text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: summary.color ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (searching) ...[
                const SizedBox(width: 10),
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else if (hasMenu)
                PopupMenuButton<VoidCallback>(
                  tooltip: 'More actions for ${plugin.name}',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (action) => action(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: () => showAliasSearchDialog(plugin.name),
                      child: const Text('Search by Alias'),
                    ),
                    PopupMenuItem(
                      value: () => showCustomSearchDialog(plugin.name),
                      child: const Text('Manual Search'),
                    ),
                    PopupMenuItem(
                      value: () => openInBrowser(plugin),
                      child: const Text('Open in Browser'),
                    ),
                  ],
                )
              else if (!open) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        );
        if (open || searching) return row;
        return InkWell(
          onTap: () => setState(() {
            expandedSource = plugin.name;
            stopAutoExpand();
          }),
          onHighlightChanged: SettingsSplitGroup.pressReporterOf(context),
          child: row,
        );
      },
    );
  }

  Widget buildResultRow(Plugin plugin, SearchItem searchItem) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => openSearchItem(plugin, searchItem),
        onHighlightChanged: SettingsSplitGroup.pressReporterOf(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  searchItem.name,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.play_arrow_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Recovery actions for a source that found nothing. Buttons keep their full
  /// Material size so they hold the 48dp tap target, and wrap rather than
  /// shrink when the row runs out of width.
  Widget buildActionsRow(Plugin plugin) {
    final theme = Theme.of(context);
    final status = widget.infoController.pluginSearchStatus[plugin.name];

    final actions = <Widget>[];
    final String hint;
    if (status == PluginSearchStatus.captcha) {
      hint = 'This source requires verification first';
      actions
          .add(buildPrimaryAction('Verify', () => showAntiCrawlerDialog(plugin)));
      actions.add(buildAction(
          'Retry', () => pluginSearchService?.querySource(keyword, plugin.name)));
    } else if (status == PluginSearchStatus.error) {
      hint = 'This source returned no results';
      actions.add(buildPrimaryAction(
          'Retry', () => pluginSearchService?.querySource(keyword, plugin.name)));
    } else {
      hint = 'Try a different keyword';
      actions.add(
          buildPrimaryAction('Search by Alias', () => showAliasSearchDialog(plugin.name)));
      actions
          .add(buildAction('Manual Search', () => showCustomSearchDialog(plugin.name)));
    }
    actions.add(buildAction('Open in Browser', () => openInBrowser(plugin)));

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Wrap(spacing: 8, runSpacing: 4, children: actions),
        ],
      ),
    );
  }

  Widget buildPrimaryAction(String label, VoidCallback onPressed) {
    return FilledButton.tonal(onPressed: onPressed, child: Text(label));
  }

  Widget buildAction(String label, VoidCallback onPressed) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }

  void showAliasSearchDialog(String pluginName) {
    if (widget.infoController.bangumiItem.alias.isEmpty) {
      KazumiDialog.showToast(message: 'No aliases available, try a manual search');
      return;
    }
    KazumiDialog.show(
      builder: (context) {
        return _AliasDialog(
          aliases: widget.infoController.bangumiItem.alias,
          onAliasSelected: (alias) {
            KazumiDialog.dismiss();
            pluginSearchService?.querySource(alias, pluginName);
          },
          onAliasesChanged: () {
            collectController
                .updateLocalCollect(widget.infoController.bangumiItem);
          },
        );
      },
    );
  }

  void showCustomSearchDialog(String pluginName) {
    String customKeyword = '';

    void submit(String value) {
      final alias = value.trim();
      if (alias.isEmpty) {
        return;
      }
      widget.infoController.bangumiItem.alias.add(alias);
      collectController.updateLocalCollect(widget.infoController.bangumiItem);
      KazumiDialog.dismiss();
      pluginSearchService?.querySource(alias, pluginName);
    }

    KazumiDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Alias'),
          content: TextField(
            onChanged: (value) => customKeyword = value,
            onSubmitted: (keyword) {
              submit(keyword);
            },
          ),
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
              onPressed: () {
                submit(customKeyword);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  /// Always plugin order, never ranked by what came back. A source can fill up
  /// long after the search settles — a captcha source does exactly that once
  /// verified — and ranking would slide the card someone just acted on out
  /// from under them. [expandedSource] is what leads to something playable.
  List<Widget> buildSourceCards() {
    final cards = <Widget>[];
    for (final plugin in pluginsController.pluginList) {
      cards.add(buildSourceCard(
        plugin,
        resultsFor(plugin.name),
        expandedSource == plugin.name,
      ));
    }
    cards.add(const SafeArea(top: false, child: SizedBox(height: 12)));
    return cards;
  }

  String? firstSourceWithResults() {
    for (final plugin in pluginsController.pluginList) {
      if (resultsFor(plugin.name).isNotEmpty) return plugin.name;
    }
    return null;
  }

  String buildProgressDescription() {
    final plugins = pluginsController.pluginList;
    final done = plugins
        .where((plugin) =>
            widget.infoController.pluginSearchStatus[plugin.name] !=
            PluginSearchStatus.pending)
        .length;
    final found = plugins.fold<int>(
        0, (sum, plugin) => sum + resultsFor(plugin.name).length);
    if (done < plugins.length) {
      return '"$keyword" · Searching $done/${plugins.length}';
    }
    return '"$keyword" · $found result(s)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Observer(
        builder: (context) {
          // Must be read here, not behind a nested Builder: mobx only tracks
          // reads made while the Observer's own builder runs.
          final cards = buildSourceCards();
          return Column(
            children: [
              MaterialBottomSheetHeader(
                title: 'Choose Playback Source',
                description: buildProgressDescription(),
                onClose: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cards.length,
                  itemBuilder: (context, index) => cards[index],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CaptchaDialog extends StatefulWidget {
  const _CaptchaDialog({
    required this.pluginName,
    required this.captchaImageStream,
    required this.onSubmit,
  });

  final String pluginName;
  final Stream<String?> captchaImageStream;
  final Future<void> Function(String captchaCode) onSubmit;

  @override
  State<_CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<_CaptchaDialog> {
  final ValueNotifier<String?> _captchaImageNotifier =
      ValueNotifier<String?>(null);
  final ValueNotifier<bool> _submittingNotifier = ValueNotifier<bool>(false);
  late final StreamSubscription<String?> _imageSub;
  String _captchaCode = '';

  @override
  void initState() {
    super.initState();
    _imageSub = widget.captchaImageStream.listen((url) {
      if (!mounted || url == null) return;
      _captchaImageNotifier.value = url;
    });
  }

  @override
  void dispose() {
    _imageSub.cancel();
    _captchaImageNotifier.dispose();
    _submittingNotifier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submittingNotifier.value) return;
    final captchaCode = _captchaCode.trim();
    if (captchaCode.isEmpty) {
      KazumiDialog.showToast(message: 'Please enter the verification code');
      return;
    }
    _submittingNotifier.value = true;
    await widget.onSubmit(captchaCode);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Captcha Verification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.pluginName} requires captcha verification',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<String?>(
                valueListenable: _captchaImageNotifier,
                builder: (context, imageUrl, _) {
                  if (imageUrl == null) {
                    return const Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading captcha image...'),
                      ],
                    );
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _submittingNotifier,
                    builder: (context, isSubmitting, _) {
                      return Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(imageUrl.split(',').last),
                              height: 80,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, _) =>
                                  const Text('Failed to decode image'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            autofocus: true,
                            enabled: !isSubmitting,
                            onChanged: (value) => _captchaCode = value,
                            decoration: const InputDecoration(
                              labelText: 'Please enter the verification code',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: isSubmitting ? null : (_) => _submit(),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: Listenable.merge([
                  _captchaImageNotifier,
                  _submittingNotifier,
                ]),
                builder: (context, _) {
                  final isImageLoading = _captchaImageNotifier.value == null;
                  final isSubmitting = _submittingNotifier.value;
                  final isDisabled = isImageLoading || isSubmitting;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => KazumiDialog.dismiss(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: isDisabled ? null : _submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Submit'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AliasDialog extends StatefulWidget {
  const _AliasDialog({
    required this.aliases,
    required this.onAliasSelected,
    required this.onAliasesChanged,
  });

  final List<String> aliases;
  final ValueChanged<String> onAliasSelected;
  final VoidCallback onAliasesChanged;

  @override
  State<_AliasDialog> createState() => _AliasDialogState();
}

class _AliasDialogState extends State<_AliasDialog> {
  late final ValueNotifier<List<String>> aliasNotifier =
      ValueNotifier<List<String>>(List.from(widget.aliases));

  @override
  void dispose() {
    aliasNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 560,
        child: ValueListenableBuilder<List<String>>(
          valueListenable: aliasNotifier,
          builder: (context, aliasList, child) {
            return ListView(
              shrinkWrap: true,
              children: aliasList.asMap().entries.map((entry) {
                final index = entry.key;
                final alias = entry.value;
                return ListTile(
                  title: Text(alias),
                  trailing: IconButton(
                    onPressed: () {
                      KazumiDialog.show(
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Confirm Delete'),
                            content: const Text('This cannot be undone. Permanently delete this alias?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  KazumiDialog.dismiss();
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  KazumiDialog.dismiss();
                                  widget.aliases.removeAt(index);
                                  aliasNotifier.value =
                                      List.from(widget.aliases);
                                  widget.onAliasesChanged();
                                  if (widget.aliases.isEmpty) {
                                    Navigator.of(this.context).pop();
                                  }
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: Icon(Icons.delete),
                  ),
                  onTap: () => widget.onAliasSelected(alias),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

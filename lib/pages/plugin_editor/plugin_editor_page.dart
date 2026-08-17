import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:kazumi/plugins/plugins.dart';
import 'package:kazumi/plugins/api_rule_config.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/plugins/plugins_controller.dart';
import 'package:kazumi/bean/appbar/sys_app_bar.dart';
import 'package:kazumi/pages/plugin_editor/editor_form_widgets.dart';
import 'package:kazumi/request/config/api_endpoints.dart';
import 'package:kazumi/services/plugin/api_rule_engine.dart';

abstract final class _RuleEditorText {
  static const pageTitle = 'Rule Editor';
  static const testRule = 'Test Rule';
  static const save = 'Save';

  static const modeXPath = 'XPath';
  static const modeApi = 'API';
  static const methodGet = 'GET';
  static const methodPost = 'POST';
  static const bodyTypeNone = 'None';
  static const bodyTypeJson = 'JSON';
  static const bodyTypeForm = 'Form';
  static const formatNested = 'Nested JSON';
  static const formatDelimited = 'Separator String';

  static const legacyParser = 'Simple Parsing';
  static const legacyParserDesc = 'Use the simple parser instead of the modern parser';
  static const adBlocker = 'Ad Filtering';
  static const adBlockerDesc = 'Enable HLS Ad Filtering';

  static const antiCrawlerEnable = 'Enable Anti-Anti-Crawler';
  static const antiCrawlerEnableDesc = 'Show the captcha verification button instead of retrying when search fails';
  static const captchaTypeLabel = 'Verification Type';
  static const captchaTypeImage = 'Image Captcha';
  static const captchaTypeAutoClick = 'Auto Click';
  static const captchaTypeScript = 'Custom Script';
  static const captchaTypeImageDesc = 'Show the captcha image for manual entry';
  static const captchaTypeAutoClickDesc = 'Automatically click when a verification button is detected';
  static const captchaTypeScriptDesc = "Run the rule's verification script after the page loads";
  static const captchaTypeUnknownDesc = 'Unknown verification type';
  static const captchaDetectTypeLabel = 'Verification Page Detection Method';
  static const captchaDetectTypeDesc = 'Prefer this marker to determine whether the search response is a verification page';
  static const captchaDetectText = 'Text';
  static const captchaDetectRegex = 'Regex';
  static const captchaDetectValueHintText = 'Identity Verification';
  static const captchaDetectValueHintRegex = 'Identity Verification|smart_verify';
  static const captchaDetectValueHintXPath = '//button[@id="verify"]';
  static const captchaImageHint = '//img[@class="captcha"]';
  static const captchaInputHint = '//input[@name="captcha"]';
  static const captchaButtonHint = '//button[@type="submit"]';
  static const captchaScriptHint =
      'KazumiCaptcha.log("ready"); KazumiCaptcha.done();';

  static const sectionBasic = 'Basic Info';
  static const sectionBasicDesc = "The rule's name, version, and site address";
  static const sectionSearch = 'Search Rule';
  static const sectionSearchDesc = 'Defines how to search for items within the site';
  static const sectionChapter = 'Episode Selection Rule';
  static const sectionChapterDesc = 'Defines how to fetch playback sources and the episode list';
  static const advancedOptions = 'Advanced Options';
  static const advancedOptionsDesc = 'Behavior, Network & Anti-Anti-Crawler Configuration';
  static const groupBehavior = 'Behavior Settings';
  static const groupNetwork = 'Network Settings';
  static const groupAntiCrawler = 'Anti-Anti-Crawler';

  static const ruleName = 'Rule Name';
  static const ruleVersion = 'Rule Version';
  static const baseUrl = 'Base URL';
  static const searchRuleType = 'Search Rule Type';
  static const chapterRuleType = 'Episode Selection Rule Type';

  static const searchUrl = 'Search URL';
  static const searchListXPath = 'Search Results List (XPath)';
  static const itemNameXPath = 'Item Name (XPath)';
  static const itemLinkXPath = 'Item Link (XPath)';
  static const roadListXPath = 'Source List (XPath)';
  static const episodeListXPath = 'Episode List (XPath)';

  static const searchMethod = 'Search Request Method';
  static const searchRequestUrl = 'Search Request URL';
  static const searchHeaders = 'Search Request Headers (JSON)';
  static const searchQuery = 'Search Query Parameters (JSON)';
  static const searchBodyType = 'Search Request Body Type';
  static const searchBody = 'Search Request Body (JSON)';
  static const searchListPath = 'Search Results List Path (JSONPath)';
  static const itemNamePath = 'Item Name Path (JSONPath, relative to item)';
  static const itemSourcePath = 'Item Source Path (JSONPath, relative to item)';

  static const chapterMethod = 'Episode Selection Request Method';
  static const chapterRequestUrl = 'Episode Selection Request URL';
  static const chapterHeaders = 'Episode Selection Request Headers (JSON)';
  static const chapterQuery = 'Episode Selection Query Parameters (JSON)';
  static const chapterBodyType = 'Episode Selection Request Body Type';
  static const chapterBody = 'Episode Selection Request Body (JSON)';
  static const chapterResponseFormat = 'Episode Selection Response Format';
  static const roadListPath = 'Source List Path (JSONPath, leave empty for a single source)';
  static const roadNamePath = 'Source Name Path (JSONPath, relative to source)';
  static const episodeListPath = 'Episode List Path (JSONPath, relative to source)';
  static const episodeNamePath = 'Episode Name Path (JSONPath, relative to episode)';
  static const playbackEntryPath = 'Playback Entry URL Path (JSONPath, can be left empty when using the playback page URL template)';
  static const playbackEntryPathHelper = 'Reads the address passed to the WebView from the episode object; can be a playback page or a direct media link.';
  static const roadNamesPath = 'Source Name String Path (JSONPath)';
  static const roadEpisodesPath = 'Source Episode String Path (JSONPath)';
  static const roadSeparator = 'Source Separator';
  static const episodeSeparator = 'Episode Separator';
  static const fieldSeparator = 'Name and Address Separator';
  static const responseVariables = 'Response Variables (JSON: variable name → JSONPath)';
  static const playPageUrl = 'Playback Page URL Template (optional)';
  static const playPageUrlHelper = 'Available variables: @source, @episodeUrl, '
      '@roadIndex/@episodeIndex (starting from 0), @roadNumber/@episodeNumber (starting from 1)'
      'and response variables.';
  static const playPageQuery = 'Playback Page Query Parameters (JSON)';
  static const playPageQueryHelper = 'Same variables as the URL template are available; merged into the final URL query parameters.';

  static const userAgent = 'User-Agent';
  static const userAgentHelper = 'Used only for the player and downloader.';
  static const referer = 'Playback Request Referer';
  static const refererHelper = 'Used only for the player and downloader.';

  static const captchaDetectValue = 'Verification Page Detection Value';
  static const captchaDetectValueHelper = 'When left empty, detection uses the XPath of the captcha image or verification button.';
  static const captchaImage = 'Captcha Image (XPath)';
  static const captchaImageHelper = 'Enter the XPath of the captcha image element.';
  static const captchaInput = 'Captcha Input Field (XPath)';
  static const captchaInputHelper = 'Enter the XPath of the captcha input field element.';
  static const captchaSubmitButton = 'Verification Submit Button (XPath)';
  static const captchaSubmitButtonHelper = 'Enter the XPath of the captcha submit button element.';
  static const verifyButton = 'Verification Button (XPath)';
  static const verifyButtonHelper = 'Enter the XPath of the verification button element; it will be clicked automatically once detected.';
  static const captchaScript = 'Verification Script (JavaScript)';
  static const captchaScriptHelper =
      'You can call KazumiCaptcha.log, clicked, done, and fail.';
}

class PluginEditorPage extends StatefulWidget {
  const PluginEditorPage({
    super.key,
    required this.plugin,
    required this.controller,
  });

  final Plugin plugin;
  final PluginsController controller;

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  PluginsController get pluginsController => widget.controller;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController versionController = TextEditingController();
  final TextEditingController userAgentController = TextEditingController();
  final TextEditingController baseURLController = TextEditingController();
  final TextEditingController searchURLController = TextEditingController();
  final TextEditingController searchListController = TextEditingController();
  final TextEditingController searchNameController = TextEditingController();
  final TextEditingController searchResultController = TextEditingController();
  final TextEditingController chapterRoadsController = TextEditingController();
  final TextEditingController chapterResultController = TextEditingController();
  final TextEditingController refererController = TextEditingController();
  final TextEditingController searchApiURLController = TextEditingController();
  final TextEditingController searchApiHeadersController =
      TextEditingController();
  final TextEditingController searchApiQueryController =
      TextEditingController();
  final TextEditingController searchApiBodyController = TextEditingController();
  final TextEditingController searchApiListPathController =
      TextEditingController();
  final TextEditingController searchApiNamePathController =
      TextEditingController();
  final TextEditingController searchApiSourcePathController =
      TextEditingController();
  final TextEditingController chapterApiURLController = TextEditingController();
  final TextEditingController chapterApiHeadersController =
      TextEditingController();
  final TextEditingController chapterApiQueryController =
      TextEditingController();
  final TextEditingController chapterApiBodyController =
      TextEditingController();
  final TextEditingController chapterApiRoadsPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadNamePathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodesPathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeNamePathController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeURLPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadNamesPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadEpisodesPathController =
      TextEditingController();
  final TextEditingController chapterApiRoadSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiEpisodeSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiFieldSeparatorController =
      TextEditingController();
  final TextEditingController chapterApiVariablesController =
      TextEditingController();
  final TextEditingController chapterApiPageURLController =
      TextEditingController();
  final TextEditingController chapterApiPageQueryController =
      TextEditingController();
  String searchMode = RuleMode.xpath;
  String chapterMode = RuleMode.xpath;
  String searchApiMethod = 'GET';
  String searchApiBodyType = ApiBodyType.none;
  String chapterApiMethod = 'GET';
  String chapterApiBodyType = ApiBodyType.none;
  String chapterApiFormat = ApiChapterFormat.nested;
  // Legacy schema values retained on save but no longer exposed as settings.
  late String _api;
  late String _type;
  late bool _muliSources;
  late bool _useWebview;
  late bool _useNativePlayer;
  bool usePost = false;
  bool useLegacyParser = false;
  bool adBlocker = false;

  // AntiCrawler fields
  final TextEditingController captchaImageController = TextEditingController();
  final TextEditingController captchaInputController = TextEditingController();
  final TextEditingController captchaButtonController = TextEditingController();
  final TextEditingController captchaDetectValueController =
      TextEditingController();
  final TextEditingController captchaScriptController = TextEditingController();
  bool antiCrawlerEnabled = false;
  int captchaType = CaptchaType.imageCaptcha;
  int captchaDetectType = CaptchaDetectType.xpath;

  static const List<ButtonSegment<String>> _ruleModeSegments = [
    ButtonSegment(
      value: RuleMode.xpath,
      label: Text(_RuleEditorText.modeXPath),
    ),
    ButtonSegment(value: RuleMode.api, label: Text(_RuleEditorText.modeApi)),
  ];

  static const List<ButtonSegment<String>> _methodSegments = [
    ButtonSegment(value: 'GET', label: Text(_RuleEditorText.methodGet)),
    ButtonSegment(value: 'POST', label: Text(_RuleEditorText.methodPost)),
  ];

  static const List<ButtonSegment<String>> _bodyTypeSegments = [
    ButtonSegment(
      value: ApiBodyType.none,
      label: Text(_RuleEditorText.bodyTypeNone),
    ),
    ButtonSegment(
      value: ApiBodyType.json,
      label: Text(_RuleEditorText.bodyTypeJson),
    ),
    ButtonSegment(
      value: ApiBodyType.form,
      label: Text(_RuleEditorText.bodyTypeForm),
    ),
  ];

  @override
  void initState() {
    super.initState();
    final Plugin plugin = widget.plugin;
    _api = plugin.api;
    _type = plugin.type;
    nameController.text = plugin.name;
    versionController.text = plugin.version;
    userAgentController.text = plugin.userAgent;
    baseURLController.text = plugin.baseUrl;
    searchURLController.text = plugin.searchURL;
    searchListController.text = plugin.searchList;
    searchNameController.text = plugin.searchName;
    searchResultController.text = plugin.searchResult;
    chapterRoadsController.text = plugin.chapterRoads;
    chapterResultController.text = plugin.chapterResult;
    refererController.text = plugin.referer;
    searchMode = plugin.searchMode;
    chapterMode = plugin.chapterMode;
    searchApiMethod = plugin.searchApiConfig.request.method;
    searchApiBodyType = plugin.searchApiConfig.request.bodyType;
    searchApiURLController.text = plugin.searchApiConfig.request.url;
    searchApiHeadersController.text =
        _prettyJson(plugin.searchApiConfig.request.headers);
    searchApiQueryController.text =
        _prettyJson(plugin.searchApiConfig.request.query);
    searchApiBodyController.text =
        _prettyJson(plugin.searchApiConfig.request.body);
    searchApiListPathController.text = plugin.searchApiConfig.listPath;
    searchApiNamePathController.text = plugin.searchApiConfig.namePath;
    searchApiSourcePathController.text = plugin.searchApiConfig.sourcePath;
    chapterApiMethod = plugin.chapterApiConfig.request.method;
    chapterApiBodyType = plugin.chapterApiConfig.request.bodyType;
    chapterApiFormat = plugin.chapterApiConfig.format;
    chapterApiURLController.text = plugin.chapterApiConfig.request.url;
    chapterApiHeadersController.text =
        _prettyJson(plugin.chapterApiConfig.request.headers);
    chapterApiQueryController.text =
        _prettyJson(plugin.chapterApiConfig.request.query);
    chapterApiBodyController.text =
        _prettyJson(plugin.chapterApiConfig.request.body);
    chapterApiRoadsPathController.text = plugin.chapterApiConfig.roadsPath;
    chapterApiRoadNamePathController.text =
        plugin.chapterApiConfig.roadNamePath;
    chapterApiEpisodesPathController.text =
        plugin.chapterApiConfig.episodesPath;
    chapterApiEpisodeNamePathController.text =
        plugin.chapterApiConfig.episodeNamePath;
    chapterApiEpisodeURLPathController.text =
        plugin.chapterApiConfig.episodeUrlPath;
    chapterApiRoadNamesPathController.text =
        plugin.chapterApiConfig.roadNamesPath;
    chapterApiRoadEpisodesPathController.text =
        plugin.chapterApiConfig.roadEpisodesPath;
    chapterApiRoadSeparatorController.text =
        plugin.chapterApiConfig.roadSeparator;
    chapterApiEpisodeSeparatorController.text =
        plugin.chapterApiConfig.episodeSeparator;
    chapterApiFieldSeparatorController.text =
        plugin.chapterApiConfig.fieldSeparator;
    chapterApiVariablesController.text =
        _prettyJson(plugin.chapterApiConfig.variables);
    chapterApiPageURLController.text =
        plugin.chapterApiConfig.episodePage?.url ?? '';
    chapterApiPageQueryController.text =
        _prettyJson(plugin.chapterApiConfig.episodePage?.query);
    _muliSources = plugin.muliSources;
    _useWebview = plugin.useWebview;
    _useNativePlayer = plugin.useNativePlayer;
    usePost = plugin.usePost;
    useLegacyParser = plugin.useLegacyParser;
    adBlocker = plugin.adBlocker;
    antiCrawlerEnabled = plugin.antiCrawlerConfig.enabled;
    captchaType = plugin.antiCrawlerConfig.captchaType;
    captchaImageController.text = plugin.antiCrawlerConfig.captchaImage;
    captchaInputController.text = plugin.antiCrawlerConfig.captchaInput;
    captchaButtonController.text = plugin.antiCrawlerConfig.captchaButton;
    captchaDetectType = plugin.antiCrawlerConfig.captchaDetectType;
    captchaDetectValueController.text =
        plugin.antiCrawlerConfig.captchaDetectValue;
    captchaScriptController.text = plugin.antiCrawlerConfig.captchaScript;
  }

  @override
  void dispose() {
    nameController.dispose();
    versionController.dispose();
    userAgentController.dispose();
    baseURLController.dispose();
    searchURLController.dispose();
    searchListController.dispose();
    searchNameController.dispose();
    searchResultController.dispose();
    chapterRoadsController.dispose();
    chapterResultController.dispose();
    refererController.dispose();
    searchApiURLController.dispose();
    searchApiHeadersController.dispose();
    searchApiQueryController.dispose();
    searchApiBodyController.dispose();
    searchApiListPathController.dispose();
    searchApiNamePathController.dispose();
    searchApiSourcePathController.dispose();
    chapterApiURLController.dispose();
    chapterApiHeadersController.dispose();
    chapterApiQueryController.dispose();
    chapterApiBodyController.dispose();
    chapterApiRoadsPathController.dispose();
    chapterApiRoadNamePathController.dispose();
    chapterApiEpisodesPathController.dispose();
    chapterApiEpisodeNamePathController.dispose();
    chapterApiEpisodeURLPathController.dispose();
    chapterApiRoadNamesPathController.dispose();
    chapterApiRoadEpisodesPathController.dispose();
    chapterApiRoadSeparatorController.dispose();
    chapterApiEpisodeSeparatorController.dispose();
    chapterApiFieldSeparatorController.dispose();
    chapterApiVariablesController.dispose();
    chapterApiPageURLController.dispose();
    chapterApiPageQueryController.dispose();
    captchaImageController.dispose();
    captchaInputController.dispose();
    captchaButtonController.dispose();
    captchaDetectValueController.dispose();
    captchaScriptController.dispose();
    super.dispose();
  }

  static String _prettyJson(Object? value) {
    if (value == null) return '';
    if (value is Map && value.isEmpty) return '{}';
    return const JsonEncoder.withIndent('  ').convert(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SysAppBar(
        title: const Text(_RuleEditorText.pageTitle),
        actions: [
          IconButton(
            tooltip: _RuleEditorText.testRule,
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () {
              final editedPlugin = _tryBuildEditedPlugin();
              if (editedPlugin == null) return;
              context.pushNamed(
                '/settings/plugin/test',
                arguments: editedPlugin,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              spacing: 16,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EditorSectionCard(
                  icon: Icons.badge_rounded,
                  title: _RuleEditorText.sectionBasic,
                  description: _RuleEditorText.sectionBasicDesc,
                  children: [
                    EditorTextField(
                      controller: nameController,
                      label: _RuleEditorText.ruleName,
                    ),
                    EditorTextField(
                      controller: versionController,
                      label: _RuleEditorText.ruleVersion,
                    ),
                    EditorTextField(
                      controller: baseURLController,
                      label: _RuleEditorText.baseUrl,
                    ),
                  ],
                ),
                EditorSectionCard(
                  icon: Icons.search_rounded,
                  title: _RuleEditorText.sectionSearch,
                  description: _RuleEditorText.sectionSearchDesc,
                  children: [
                    EditorSegmentedField<String>(
                      label: _RuleEditorText.searchRuleType,
                      value: searchMode,
                      segments: _ruleModeSegments,
                      onChanged: (value) => setState(() => searchMode = value),
                    ),
                    EditorAnimatedSection(
                      activeKey: searchMode,
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: searchMode == RuleMode.xpath
                            ? _buildXPathSearchFields()
                            : _buildApiSearchFields(),
                      ),
                    ),
                  ],
                ),
                EditorSectionCard(
                  icon: Icons.playlist_play_rounded,
                  title: _RuleEditorText.sectionChapter,
                  description: _RuleEditorText.sectionChapterDesc,
                  children: [
                    EditorSegmentedField<String>(
                      label: _RuleEditorText.chapterRuleType,
                      value: chapterMode,
                      segments: _ruleModeSegments,
                      onChanged: (value) => setState(() => chapterMode = value),
                    ),
                    EditorAnimatedSection(
                      activeKey: chapterMode,
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: chapterMode == RuleMode.xpath
                            ? _buildXPathChapterFields()
                            : _buildApiChapterFields(),
                      ),
                    ),
                  ],
                ),
                _buildAdvancedOptionsCard(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        icon: const Icon(Icons.save_rounded),
        label: const Text(_RuleEditorText.save),
        onPressed: () async {
          final editedPlugin = _tryBuildEditedPlugin();
          if (editedPlugin == null) return;
          try {
            await pluginsController.updatePlugin(editedPlugin);
          } catch (error) {
            _showEditorError(error);
            return;
          }
          if (!context.mounted) return;
          context.pop();
        },
      ),
    );
  }

  Widget _buildAdvancedOptionsCard() {
    return EditorExpandableSectionCard(
      icon: Icons.tune_rounded,
      title: _RuleEditorText.advancedOptions,
      description: _RuleEditorText.advancedOptionsDesc,
      children: [
        const EditorSubheader(label: _RuleEditorText.groupBehavior),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(_RuleEditorText.legacyParser),
          subtitle: const Text(_RuleEditorText.legacyParserDesc),
          value: useLegacyParser,
          onChanged: (value) => setState(() => useLegacyParser = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(_RuleEditorText.adBlocker),
          subtitle: const Text(_RuleEditorText.adBlockerDesc),
          value: adBlocker,
          onChanged: (value) => setState(() => adBlocker = value),
        ),
        const EditorSubheader(label: _RuleEditorText.groupNetwork),
        EditorTextField(
          controller: userAgentController,
          label: _RuleEditorText.userAgent,
          helper: _RuleEditorText.userAgentHelper,
        ),
        const SizedBox(height: 16),
        EditorTextField(
          controller: refererController,
          label: _RuleEditorText.referer,
          helper: _RuleEditorText.refererHelper,
        ),
        if (searchMode == RuleMode.xpath) ...[
          const EditorSubheader(label: _RuleEditorText.groupAntiCrawler),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(_RuleEditorText.antiCrawlerEnable),
            subtitle: const Text(_RuleEditorText.antiCrawlerEnableDesc),
            value: antiCrawlerEnabled,
            onChanged: (value) => setState(() => antiCrawlerEnabled = value),
          ),
          EditorAnimatedSection(
            activeKey: antiCrawlerEnabled,
            child: antiCrawlerEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      spacing: 16,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildAntiCrawlerFields(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildAntiCrawlerFields() => [
        EditorSegmentedField<int>(
          label: _RuleEditorText.captchaTypeLabel,
          value: captchaType,
          segments: const [
            ButtonSegment(
              value: CaptchaType.imageCaptcha,
              label: Text(_RuleEditorText.captchaTypeImage),
            ),
            ButtonSegment(
              value: CaptchaType.autoClickButton,
              label: Text(_RuleEditorText.captchaTypeAutoClick),
            ),
            ButtonSegment(
              value: CaptchaType.customJavaScript,
              label: Text(_RuleEditorText.captchaTypeScript),
            ),
          ],
          onChanged: (value) => setState(() => captchaType = value),
          description: (value) => switch (value) {
            CaptchaType.imageCaptcha => _RuleEditorText.captchaTypeImageDesc,
            CaptchaType.autoClickButton =>
              _RuleEditorText.captchaTypeAutoClickDesc,
            CaptchaType.customJavaScript =>
              _RuleEditorText.captchaTypeScriptDesc,
            _ => _RuleEditorText.captchaTypeUnknownDesc,
          },
        ),
        EditorSegmentedField<int>(
          label: _RuleEditorText.captchaDetectTypeLabel,
          value: captchaDetectType,
          segments: const [
            ButtonSegment(
              value: CaptchaDetectType.xpath,
              label: Text(_RuleEditorText.modeXPath),
            ),
            ButtonSegment(
              value: CaptchaDetectType.text,
              label: Text(_RuleEditorText.captchaDetectText),
            ),
            ButtonSegment(
              value: CaptchaDetectType.regex,
              label: Text(_RuleEditorText.captchaDetectRegex),
            ),
          ],
          onChanged: (value) => setState(() => captchaDetectType = value),
          description: (_) => _RuleEditorText.captchaDetectTypeDesc,
        ),
        EditorTextField(
          controller: captchaDetectValueController,
          label: _RuleEditorText.captchaDetectValue,
          hint: captchaDetectType == CaptchaDetectType.text
              ? _RuleEditorText.captchaDetectValueHintText
              : captchaDetectType == CaptchaDetectType.regex
                  ? _RuleEditorText.captchaDetectValueHintRegex
                  : _RuleEditorText.captchaDetectValueHintXPath,
          helper: _RuleEditorText.captchaDetectValueHelper,
        ),
        EditorAnimatedSection(
          activeKey: captchaType,
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (captchaType == CaptchaType.imageCaptcha) ...[
                EditorTextField(
                  controller: captchaImageController,
                  label: _RuleEditorText.captchaImage,
                  hint: _RuleEditorText.captchaImageHint,
                  helper: _RuleEditorText.captchaImageHelper,
                ),
                EditorTextField(
                  controller: captchaInputController,
                  label: _RuleEditorText.captchaInput,
                  hint: _RuleEditorText.captchaInputHint,
                  helper: _RuleEditorText.captchaInputHelper,
                ),
              ],
              if (captchaType != CaptchaType.customJavaScript)
                EditorTextField(
                  controller: captchaButtonController,
                  label: captchaType == CaptchaType.imageCaptcha
                      ? _RuleEditorText.captchaSubmitButton
                      : _RuleEditorText.verifyButton,
                  hint: _RuleEditorText.captchaButtonHint,
                  helper: captchaType == CaptchaType.imageCaptcha
                      ? _RuleEditorText.captchaSubmitButtonHelper
                      : _RuleEditorText.verifyButtonHelper,
                ),
              if (captchaType == CaptchaType.customJavaScript)
                EditorTextField(
                  controller: captchaScriptController,
                  label: _RuleEditorText.captchaScript,
                  hint: _RuleEditorText.captchaScriptHint,
                  helper: _RuleEditorText.captchaScriptHelper,
                  maxLines: 8,
                ),
            ],
          ),
        ),
      ];

  List<Widget> _buildXPathSearchFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchMethod,
          value: usePost ? 'POST' : 'GET',
          segments: _methodSegments,
          onChanged: (value) => setState(() => usePost = value == 'POST'),
        ),
        EditorTextField(
          controller: searchURLController,
          label: _RuleEditorText.searchUrl,
        ),
        EditorTextField(
          controller: searchListController,
          label: _RuleEditorText.searchListXPath,
        ),
        EditorTextField(
          controller: searchNameController,
          label: _RuleEditorText.itemNameXPath,
        ),
        EditorTextField(
          controller: searchResultController,
          label: _RuleEditorText.itemLinkXPath,
        ),
      ];

  List<Widget> _buildXPathChapterFields() => [
        EditorTextField(
          controller: chapterRoadsController,
          label: _RuleEditorText.roadListXPath,
        ),
        EditorTextField(
          controller: chapterResultController,
          label: _RuleEditorText.episodeListXPath,
        ),
      ];

  List<Widget> _buildApiSearchFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchMethod,
          value: searchApiMethod,
          segments: _methodSegments,
          onChanged: (value) => setState(() => searchApiMethod = value),
        ),
        EditorTextField(
          controller: searchApiURLController,
          label: _RuleEditorText.searchRequestUrl,
        ),
        EditorTextField(
          controller: searchApiHeadersController,
          label: _RuleEditorText.searchHeaders,
          maxLines: 4,
        ),
        EditorTextField(
          controller: searchApiQueryController,
          label: _RuleEditorText.searchQuery,
          maxLines: 4,
        ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.searchBodyType,
          value: searchApiBodyType,
          segments: _bodyTypeSegments,
          onChanged: (value) => setState(() => searchApiBodyType = value),
        ),
        if (searchApiBodyType != ApiBodyType.none)
          EditorTextField(
            controller: searchApiBodyController,
            label: _RuleEditorText.searchBody,
            maxLines: 5,
          ),
        EditorTextField(
          controller: searchApiListPathController,
          label: _RuleEditorText.searchListPath,
        ),
        EditorTextField(
          controller: searchApiNamePathController,
          label: _RuleEditorText.itemNamePath,
        ),
        EditorTextField(
          controller: searchApiSourcePathController,
          label: _RuleEditorText.itemSourcePath,
        ),
      ];

  List<Widget> _buildApiChapterFields() => [
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterMethod,
          value: chapterApiMethod,
          segments: _methodSegments,
          onChanged: (value) => setState(() => chapterApiMethod = value),
        ),
        EditorTextField(
          controller: chapterApiURLController,
          label: _RuleEditorText.chapterRequestUrl,
        ),
        EditorTextField(
          controller: chapterApiHeadersController,
          label: _RuleEditorText.chapterHeaders,
          maxLines: 4,
        ),
        EditorTextField(
          controller: chapterApiQueryController,
          label: _RuleEditorText.chapterQuery,
          maxLines: 4,
        ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterBodyType,
          value: chapterApiBodyType,
          segments: _bodyTypeSegments,
          onChanged: (value) => setState(() => chapterApiBodyType = value),
        ),
        if (chapterApiBodyType != ApiBodyType.none)
          EditorTextField(
            controller: chapterApiBodyController,
            label: _RuleEditorText.chapterBody,
            maxLines: 5,
          ),
        EditorSegmentedField<String>(
          label: _RuleEditorText.chapterResponseFormat,
          value: chapterApiFormat,
          segments: const [
            ButtonSegment(
              value: ApiChapterFormat.nested,
              label: Text(_RuleEditorText.formatNested),
            ),
            ButtonSegment(
              value: ApiChapterFormat.delimited,
              label: Text(_RuleEditorText.formatDelimited),
            ),
          ],
          onChanged: (value) => setState(() => chapterApiFormat = value),
        ),
        EditorAnimatedSection(
          activeKey: chapterApiFormat,
          child: Column(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: chapterApiFormat == ApiChapterFormat.nested
                ? [
                    EditorTextField(
                      controller: chapterApiRoadsPathController,
                      label: _RuleEditorText.roadListPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadNamePathController,
                      label: _RuleEditorText.roadNamePath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodesPathController,
                      label: _RuleEditorText.episodeListPath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeNamePathController,
                      label: _RuleEditorText.episodeNamePath,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeURLPathController,
                      label: _RuleEditorText.playbackEntryPath,
                      helper: _RuleEditorText.playbackEntryPathHelper,
                    ),
                  ]
                : [
                    EditorTextField(
                      controller: chapterApiRoadNamesPathController,
                      label: _RuleEditorText.roadNamesPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadEpisodesPathController,
                      label: _RuleEditorText.roadEpisodesPath,
                    ),
                    EditorTextField(
                      controller: chapterApiRoadSeparatorController,
                      label: _RuleEditorText.roadSeparator,
                    ),
                    EditorTextField(
                      controller: chapterApiEpisodeSeparatorController,
                      label: _RuleEditorText.episodeSeparator,
                    ),
                    EditorTextField(
                      controller: chapterApiFieldSeparatorController,
                      label: _RuleEditorText.fieldSeparator,
                    ),
                  ],
          ),
        ),
        EditorTextField(
          controller: chapterApiVariablesController,
          label: _RuleEditorText.responseVariables,
          maxLines: 5,
        ),
        EditorTextField(
          controller: chapterApiPageURLController,
          label: _RuleEditorText.playPageUrl,
          helper: _RuleEditorText.playPageUrlHelper,
        ),
        EditorTextField(
          controller: chapterApiPageQueryController,
          label: _RuleEditorText.playPageQuery,
          helper: _RuleEditorText.playPageQueryHelper,
          maxLines: 5,
        ),
      ];

  /// Builds the edited plugin, surfacing build/validation errors to the
  /// user. Returns null when the current input does not form a valid rule.
  Plugin? _tryBuildEditedPlugin() {
    try {
      return _buildEditedPlugin();
    } catch (error) {
      _showEditorError(error);
      return null;
    }
  }

  Plugin _buildEditedPlugin() {
    final searchConfig = _buildSearchApiConfig();
    final chapterConfig = _buildChapterApiConfig();
    return Plugin(
      api: searchMode == RuleMode.api || chapterMode == RuleMode.api
          ? ApiEndpoints.apiLevel.toString()
          : _api,
      type: _type,
      name: nameController.text,
      version: versionController.text,
      muliSources: _muliSources,
      useWebview: _useWebview,
      useNativePlayer: _useNativePlayer,
      usePost: usePost,
      useLegacyParser: useLegacyParser,
      adBlocker: adBlocker,
      userAgent: userAgentController.text,
      baseUrl: baseURLController.text,
      searchURL: searchURLController.text,
      searchList: searchListController.text,
      searchName: searchNameController.text,
      searchResult: searchResultController.text,
      chapterRoads: chapterRoadsController.text,
      chapterResult: chapterResultController.text,
      referer: refererController.text,
      searchMode: searchMode,
      chapterMode: chapterMode,
      searchApiConfig: searchConfig,
      chapterApiConfig: chapterConfig,
      antiCrawlerConfig: AntiCrawlerConfig(
        enabled: antiCrawlerEnabled,
        captchaType: captchaType,
        captchaImage: captchaImageController.text,
        captchaInput: captchaInputController.text,
        captchaButton: captchaButtonController.text,
        captchaDetectType: captchaDetectType,
        captchaDetectValue: captchaDetectValueController.text,
        captchaScript: captchaScriptController.text,
      ),
    );
  }

  ApiSearchConfig _buildSearchApiConfig() {
    final shouldValidate = searchMode == RuleMode.api;
    String valueOf(TextEditingController controller) =>
        shouldValidate ? controller.text.trim() : controller.text;
    final config = ApiSearchConfig(
      request: ApiRequestConfig(
        method: searchApiMethod,
        url: valueOf(searchApiURLController),
        headers: _parseJsonMap(searchApiHeadersController, 'Search Request Headers'),
        query: _parseJsonMap(searchApiQueryController, 'Search Query Parameters'),
        bodyType: searchApiBodyType,
        body: _parseBody(
          searchApiBodyController,
          searchApiBodyType,
          'Search Request Body',
        ),
      ),
      listPath: valueOf(searchApiListPathController),
      namePath: valueOf(searchApiNamePathController),
      sourcePath: valueOf(searchApiSourcePathController),
    );
    if (!shouldValidate) return config;
    if (config.request.url.isEmpty) {
      throw const FormatException('Search request URL cannot be empty');
    }
    const ApiRuleStrategy()
      ..prepareRequest(config.request, const {'keyword': 'test'})
      ..validateSearchConfig(config);
    return config;
  }

  ApiChapterConfig _buildChapterApiConfig() {
    final pageUrl = chapterApiPageURLController.text.trim();
    final variablesRaw = _parseJsonMap(
      chapterApiVariablesController,
      'Episode Selection Response Variables',
    );
    final config = ApiChapterConfig(
      request: ApiRequestConfig(
        method: chapterApiMethod,
        url: chapterApiURLController.text.trim(),
        headers: _parseJsonMap(chapterApiHeadersController, 'Episode Selection Request Headers'),
        query: _parseJsonMap(chapterApiQueryController, 'Episode Selection Query Parameters'),
        bodyType: chapterApiBodyType,
        body: _parseBody(
          chapterApiBodyController,
          chapterApiBodyType,
          'Episode Selection Request Body',
        ),
      ),
      format: chapterApiFormat,
      roadsPath: chapterApiRoadsPathController.text.trim(),
      roadNamePath: chapterApiRoadNamePathController.text.trim(),
      episodesPath: chapterApiEpisodesPathController.text.trim(),
      episodeNamePath: chapterApiEpisodeNamePathController.text.trim(),
      episodeUrlPath: chapterApiEpisodeURLPathController.text.trim(),
      roadNamesPath: chapterApiRoadNamesPathController.text.trim(),
      roadEpisodesPath: chapterApiRoadEpisodesPathController.text.trim(),
      roadSeparator: chapterApiRoadSeparatorController.text,
      episodeSeparator: chapterApiEpisodeSeparatorController.text,
      fieldSeparator: chapterApiFieldSeparatorController.text,
      variables: variablesRaw.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      episodePage: pageUrl.isEmpty
          ? null
          : ApiEpisodePageConfig(
              url: pageUrl,
              query: _parseJsonMap(
                chapterApiPageQueryController,
                'Playback Page Query Parameters',
              ),
            ),
    );
    if (chapterMode != RuleMode.api) return config;
    if (config.request.url.isEmpty) {
      throw const FormatException('Episode selection request URL cannot be empty');
    }
    const ApiRuleStrategy()
      ..prepareRequest(config.request, const {'source': 'test'})
      ..validateChapterConfig(config);
    return config;
  }

  Map<String, dynamic> _parseJsonMap(
    TextEditingController controller,
    String label,
  ) {
    final text = controller.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final value = jsonDecode(text);
    if (value is! Map) throw FormatException('$label must be a JSON object');
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  dynamic _parseBody(
    TextEditingController controller,
    String bodyType,
    String label,
  ) {
    if (bodyType == ApiBodyType.none) return null;
    final text = controller.text.trim();
    if (text.isEmpty) return <String, dynamic>{};
    final dynamic value;
    try {
      value = jsonDecode(text);
    } on FormatException catch (error) {
      throw FormatException('$label is not valid JSON: ${error.message}');
    }
    if (bodyType == ApiBodyType.form && value is! Map) {
      throw FormatException('$label must be a JSON object in form mode');
    }
    return value;
  }

  void _showEditorError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString())),
    );
  }
}

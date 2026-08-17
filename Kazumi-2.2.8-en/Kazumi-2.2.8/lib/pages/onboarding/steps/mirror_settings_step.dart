import 'package:flutter/material.dart';
import 'package:kazumi/pages/onboarding/onboarding_step_layout.dart';
import 'package:kazumi/services/storage/storage.dart';

class MirrorSettingsStep extends StatefulWidget {
  const MirrorSettingsStep({super.key});

  @override
  State<MirrorSettingsStep> createState() => _MirrorSettingsStepState();
}

class _MirrorSettingsStepState extends State<MirrorSettingsStep> {
  late bool enableGitProxy;
  late bool enableBangumiProxy;

  @override
  void initState() {
    super.initState();
    enableGitProxy = GStorage.getSetting(SettingsKeys.enableGitProxy);
    enableBangumiProxy = GStorage.getSetting(SettingsKeys.enableBangumiProxy);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OnboardingStepLayout(
      leading: const OnboardingStepIcon(icon: Icons.public_rounded),
      title: 'Network Mirror',
      subtitle: 'Recommended for users in mainland China to improve access speed',
      child: Align(
        alignment: Alignment.topCenter,
        child: Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: colorScheme.surfaceContainerLow,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.travel_explore_rounded),
                title: const Text('Bangumi Mirror'),
                subtitle: const Text('Speed up loading of trending and schedule data'),
                value: enableBangumiProxy,
                onChanged: (value) async {
                  enableBangumiProxy = value;
                  await GStorage.putSetting(
                      SettingsKeys.enableBangumiProxy, value);
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.extension_rounded),
                title: const Text('Rule Repository Mirror'),
                subtitle: const Text('Speed up rule downloads and updates'),
                value: enableGitProxy,
                onChanged: (value) async {
                  enableGitProxy = value;
                  await GStorage.putSetting(SettingsKeys.enableGitProxy, value);
                  if (mounted) {
                    setState(() {});
                  }
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You can change this later in Settings → Sync Settings',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

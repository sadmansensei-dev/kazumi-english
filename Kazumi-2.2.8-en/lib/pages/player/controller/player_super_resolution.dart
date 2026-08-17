enum SuperResolutionMode {
  off(
    storageValue: 1,
    label: 'Close',
    description: 'Disable super resolution by default',
  ),
  efficiency(
    storageValue: 2,
    label: 'Efficiency Tier',
    description: 'Enable Anime4K-based super resolution by default (efficiency priority)',
  ),
  quality(
    storageValue: 3,
    label: 'Quality Tier',
    description: 'Enable Anime4K-based super resolution by default (quality priority)',
  );

  const SuperResolutionMode({
    required this.storageValue,
    required this.label,
    required this.description,
  });

  final int storageValue;
  final String label;
  final String description;

  static SuperResolutionMode fromStorageValue(int value) {
    return SuperResolutionMode.values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => SuperResolutionMode.off,
    );
  }
}

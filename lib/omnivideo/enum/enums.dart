enum AssetSource {
  localVideo,
  localPhoto,
  onlineVideo,
  onlineImage,
}

class PickedAsset {
  final String id;
  final AssetSource source;
  final String pathOrUrl;

  PickedAsset({
    required this.id,
    required this.source,
    required this.pathOrUrl,
  });
}

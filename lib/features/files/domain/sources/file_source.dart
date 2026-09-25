/// A file the user picked, decoupled from `file_picker` so controllers and
/// tests never depend on a platform plugin.
class PickedFile {
  const PickedFile({
    required this.name,
    this.path,
    this.size = 0,
    this.bytes,
  });

  final String name;
  final String? path;
  final int size;
  final List<int>? bytes;
}

/// Abstraction over the platform picker.
abstract interface class FileSource {
  /// Returns `null` when the user dismissed the picker.
  Future<PickedFile?> pick();
}

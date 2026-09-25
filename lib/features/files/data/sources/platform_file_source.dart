import 'package:file_picker/file_picker.dart';

import '../../../../core/config/file_engine_config.dart';
import '../../domain/sources/file_source.dart';

/// Real platform picker, filtered to [FileEngineConfig.supportedExtensions].
///
/// `withData` stays off so large documents are streamed from disk instead of
/// being copied into the Dart heap before validation even ran.
class PlatformFileSource implements FileSource {
  const PlatformFileSource();

  @override
  Future<PickedFile?> pick() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FileEngineConfig.pickerExtensions,
      allowMultiple: false,
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    return PickedFile(
      name: file.name,
      path: file.path,
      size: file.size,
      bytes: file.bytes,
    );
  }
}

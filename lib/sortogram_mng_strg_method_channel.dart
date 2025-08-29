import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'sortogram_mng_strg_platform_interface.dart';
import 'sortogram_mng_strg.dart';

/// An implementation of [SortogramMngStrgPlatform] that uses method channels.
class MethodChannelSortogramMngStrg extends SortogramMngStrgPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('sortogram_mng_strg');

  @override
  Future<String?> getPlatformVersion() async {
    debugPrint('[Method Channel] Getting platform version...');
    try {
      final version = await methodChannel.invokeMethod<String>(
        'getPlatformVersion',
      );
      debugPrint('[Method Channel] Platform version result: $version');
      return version;
    } catch (e, stack) {
      debugPrint('[Method Channel] Error getting platform version: $e');
      debugPrint('[Method Channel] Stack trace: $stack');
      rethrow;
    }
  }

  @override
  Future<bool> moveImage({
    required String sourcePath,
    required String destinationPath,
  }) async {
    debugPrint('[Method Channel] Moving image...');
    debugPrint('[Method Channel] Source: $sourcePath');
    debugPrint('[Method Channel] Destination: $destinationPath');

    try {
      debugPrint('[Method Channel] Invoking native moveImage method');
      final result = await methodChannel.invokeMethod<bool>('moveImage', {
        'sourcePath': sourcePath,
        'destinationPath': destinationPath,
      });
      debugPrint('[Method Channel] Move result: ${result ?? false}');
      return result ?? false;
    } catch (e, stack) {
      debugPrint('[Method Channel] Error during move operation: $e');
      debugPrint('[Method Channel] Stack trace: $stack');

      if (e is PlatformException) {
        debugPrint('[Method Channel] Platform exception details:');
        debugPrint('  Code: ${e.code}');
        debugPrint('  Message: ${e.message}');
        debugPrint('  Details: ${e.details}');

        throw ImageMoveException(
          e.code,
          e.message ?? 'Unknown error',
          e.details,
        );
      }
      rethrow;
    }
  }
}

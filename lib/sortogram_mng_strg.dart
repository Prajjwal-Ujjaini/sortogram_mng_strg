import 'package:flutter/foundation.dart';
import 'sortogram_mng_strg_platform_interface.dart';

/// Exception thrown when image moving operations fail
class ImageMoveException implements Exception {
  final String code;
  final String message;
  final dynamic details;

  ImageMoveException(this.code, this.message, [this.details]);

  @override
  String toString() => 'ImageMoveException($code): $message';
}

/// Main class for the Sortogram Storage Management plugin
class SortogramMngStrg {
  /// Gets the platform version
  Future<String?> getPlatformVersion() async {
    debugPrint('Getting platform version...');
    final version = await SortogramMngStrgPlatform.instance
        .getPlatformVersion();
    debugPrint('Platform version: $version');
    return version;
  }

  /// Moves an image file from one location to another while properly updating the MediaStore
  ///
  /// [sourcePath] is the absolute path to the source image file
  /// [destinationPath] is the absolute path where the image should be moved to
  ///
  /// Returns `true` if the move was successful
  ///
  /// Throws [ImageMoveException] if:
  /// - The source file doesn't exist
  /// - The destination already exists
  /// - The file type is not supported (supported: jpg, jpeg, png, webp)
  /// - Required permissions are not granted
  /// - Any other error occurs during the move operation
  Future<bool> moveImage({
    required String sourcePath,
    required String destinationPath,
  }) async {
    debugPrint(
      '\n\n\n ***************************Moving image...***************************',
    );
    debugPrint('Source: $sourcePath');
    debugPrint('Destination: $destinationPath');

    try {
      final result = await SortogramMngStrgPlatform.instance.moveImage(
        sourcePath: sourcePath,
        destinationPath: destinationPath,
      );
      debugPrint('Move operation ${result ? 'successful' : 'failed'}');
      debugPrint(
        '\n\n\n ********************Moving Done...***************************',
      );
      return result;
    } catch (e, stack) {
      debugPrint('Error moving image: $e');
      debugPrint('Stack trace: $stack');
      debugPrint(
        '\n\n\n ************************Moving Not Done... Error occure ***************************',
      );
      rethrow;
    }
  }

  /// Copies an image file from one location to another while properly updating the MediaStore
  ///
  /// [sourcePath] is the absolute path to the source image file
  /// [destinationPath] is the absolute path where the image should be copied to
  ///
  /// Returns `true` if the copy was successful
  ///
  /// Throws [ImageMoveException] if:
  /// - The source file doesn't exist
  /// - The destination already exists
  /// - The file type is not supported (supported: jpg, jpeg, png, webp)
  /// - Required permissions are not granted
  /// - Any other error occurs during the copy operation
  Future<bool> copyImage({
    required String sourcePath,
    required String destinationPath,
  }) async {
    debugPrint(
      '\n\n\n ***************************Copying image...***************************',
    );
    debugPrint('Source: $sourcePath');
    debugPrint('Destination: $destinationPath');

    try {
      final result = await SortogramMngStrgPlatform.instance.copyImage(
        sourcePath: sourcePath,
        destinationPath: destinationPath,
      );
      debugPrint('Copy operation ${result ? 'successful' : 'failed'}');
      debugPrint(
        '\n\n\n ********************Copying Done...***************************',
      );
      return result;
    } catch (e, stack) {
      debugPrint('Error copying image: $e');
      debugPrint('Stack trace: $stack');
      debugPrint(
        '\n\n\n ************************Copying Not Done... Error occurred ***************************',
      );
      rethrow;
    }
  }
}

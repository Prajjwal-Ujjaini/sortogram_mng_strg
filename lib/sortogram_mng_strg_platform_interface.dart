import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'sortogram_mng_strg_method_channel.dart';

abstract class SortogramMngStrgPlatform extends PlatformInterface {
  /// Constructs a SortogramMngStrgPlatform.
  SortogramMngStrgPlatform() : super(token: _token);

  static final Object _token = Object();

  static SortogramMngStrgPlatform _instance = MethodChannelSortogramMngStrg();

  /// The default instance of [SortogramMngStrgPlatform] to use.
  ///
  /// Defaults to [MethodChannelSortogramMngStrg].
  static SortogramMngStrgPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SortogramMngStrgPlatform] when
  /// they register themselves.
  static set instance(SortogramMngStrgPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    debugPrint('[Platform Interface] Getting platform version');
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Moves an image file from one location to another while properly updating the MediaStore
  ///
  /// [sourcePath] is the absolute path to the source image file
  /// [destinationPath] is the absolute path where the image should be moved to
  ///
  /// Returns `true` if the move was successful
  ///
  /// Throws PlatformException if:
  /// - The source file doesn't exist
  /// - The destination already exists
  /// - The file type is not supported (supported: jpg, jpeg, png, webp)
  /// - Required permissions are not granted
  /// - Any other error occurs during the move operation
  Future<bool> moveImage({
    required String sourcePath,
    required String destinationPath,
  }) {
    debugPrint('[Platform Interface] moveImage() called but not implemented');
    debugPrint('[Platform Interface] Source: $sourcePath');
    debugPrint('[Platform Interface] Destination: $destinationPath');
    throw UnimplementedError('moveImage() has not been implemented.');
  }

  /// Copies an image file from one location to another while properly updating the MediaStore
  ///
  /// [sourcePath] is the absolute path to the source image file
  /// [destinationPath] is the absolute path where the image should be copied to
  ///
  /// Returns `true` if the copy was successful
  ///
  /// Throws PlatformException if:
  /// - The source file doesn't exist
  /// - The destination already exists
  /// - The file type is not supported (supported: jpg, jpeg, png, webp)
  /// - Required permissions are not granted
  /// - Any other error occurs during the copy operation
  Future<bool> copyImage({
    required String sourcePath,
    required String destinationPath,
  }) {
    debugPrint('[Platform Interface] copyImage() called but not implemented');
    debugPrint('[Platform Interface] Source: $sourcePath');
    debugPrint('[Platform Interface] Destination: $destinationPath');
    throw UnimplementedError('copyImage() has not been implemented.');
  }
}

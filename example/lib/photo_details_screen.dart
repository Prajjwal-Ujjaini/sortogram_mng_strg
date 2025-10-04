import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sortogram_mng_strg/sortogram_mng_strg.dart';
import 'main.dart';

class PhotoDetailsScreen extends StatefulWidget {
  final AssetEntity photo;

  const PhotoDetailsScreen({super.key, required this.photo});

  @override
  State<PhotoDetailsScreen> createState() => _PhotoDetailsScreenState();
}

class _PhotoDetailsScreenState extends State<PhotoDetailsScreen> {
  bool _isMoving = false;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Details'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'move') {
                _showMoveDialog();
              } else if (value == 'copy') {
                _showCopyDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'move',
                child: Row(
                  children: [
                    Icon(Icons.drive_file_move),
                    SizedBox(width: 8),
                    Text('Move to Album'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.file_copy),
                    SizedBox(width: 8),
                    Text('Copy to Album'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AssetEntityImage(
                widget.photo,
                isOriginal: true,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Text('Error loading image: $error')),
              ),
            ),
            if (_statusMessage != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black87,
                child: Text(
                  _statusMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (_isMoving) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveDialog() async {
    // Get all albums to show as destination options
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
    );

    if (!mounted) return;

    final destinationAlbum = await showDialog<AssetPathEntity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Album'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                title: Text(album.name),
                onTap: () => Navigator.pop(context, album),
              );
            },
          ),
        ),
      ),
    );

    if (destinationAlbum != null) {
      await _movePhotoToAlbum(destinationAlbum);
    }
  }

  Future<void> _showCopyDialog() async {
    // Get all albums to show as destination options
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: false,
    );

    if (!mounted) return;

    final destinationAlbum = await showDialog<AssetPathEntity>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Copy to Album'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return ListTile(
                title: Text(album.name),
                onTap: () => Navigator.pop(context, album),
              );
            },
          ),
        ),
      ),
    );

    if (destinationAlbum != null) {
      await _copyPhotoToAlbum(destinationAlbum);
    }
  }

  Future<void> _copyPhotoToAlbum(AssetPathEntity destinationAlbum) async {
    setState(() {
      _isMoving = true;
      _statusMessage = 'Preparing to copy photo...';
    });

    try {
      // Get the source file
      final file = await widget.photo.file;
      if (file == null) {
        setState(() {
          _statusMessage = 'Error: Could not access the photo file';
          _isMoving = false;
        });
        return;
      }

      // Get the destination directory
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) {
        setState(() {
          _statusMessage = 'Error: Could not access storage';
          _isMoving = false;
        });
        return;
      }

      // Create the destination path
      final destinationDir = Directory(
        path.join(
          appDir.parent.parent.parent.parent.path,
          'Pictures',
          destinationAlbum.name,
        ),
      );

      // Create directory if it doesn't exist
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      // Generate destination file path
      final fileName = path.basename(file.path);
      final destinationPath = path.join(destinationDir.path, fileName);

      // Copy the file using our plugin
      setState(() => _statusMessage = 'Copying photo...');
      final plugin = SortogramMngStrg();
      final success = await plugin.copyImage(
        sourcePath: file.path,
        destinationPath: destinationPath,
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _statusMessage = 'Failed to copy photo';
          _isMoving = false;
        });
        return;
      }

      // Show success and refresh the screen
      setState(() {
        _statusMessage = 'Photo copied successfully';
        _isMoving = false;
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo copied successfully')),
      );

      // Refresh the app to show the new copy
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error copying photo: $e';
        _isMoving = false;
      });
    }
  }

  Future<void> _movePhotoToAlbum(AssetPathEntity destinationAlbum) async {
    setState(() {
      _isMoving = true;
      _statusMessage = 'Preparing to move photo...';
    });

    try {
      // Get the source file
      final file = await widget.photo.file;
      if (file == null) {
        setState(() {
          _statusMessage = 'Error: Could not access the photo file';
          _isMoving = false;
        });
        return;
      }

      // Get the destination directory
      final appDir = await getExternalStorageDirectory();
      if (appDir == null) {
        setState(() {
          _statusMessage = 'Error: Could not access storage';
          _isMoving = false;
        });
        return;
      }

      print('appDir : ${appDir}');
      print('AppDir path : ${appDir.path}');
      print('AppDir parent path : ${appDir.parent.path}');
      print('AppDir parent.parent path : ${appDir.parent.parent.path}');
      print(
        'AppDir parent.parent.parent path : ${appDir.parent.parent.parent.path}',
      );
      print(
        'AppDir parent.parent.parent.parent path : ${appDir.parent.parent.parent.parent.path}',
      );
      print(
        '---AppDir parent.parent.parent.parent Pictures path : ${path.join(appDir.parent.parent.parent.parent.path, 'Pictures')}',
      );

      // Create the destination path
      final destinationDir = Directory(
        path.join(
          appDir.parent.parent.parent.parent.path,
          'Pictures',
          destinationAlbum.name,
        ),
      );

      print('destinationDir : ${destinationDir}');

      // Create directory if it doesn't exist
      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      // Generate destination file path
      final fileName = path.basename(file.path);
      print('fileName : ${fileName}');

      print('sourcePath : ${file.path}');

      final destinationPath = path.join(destinationDir.path, fileName);
      print('destinationPath : ${destinationPath}');

      // Move the file using our plugin
      setState(() => _statusMessage = 'Moving photo...');
      final plugin = SortogramMngStrg();
      final success = await plugin.moveImage(
        sourcePath: file.path,
        destinationPath: destinationPath,
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _statusMessage = 'Failed to move photo';
          _isMoving = false;
        });
        return;
      }

      // Show success and pop back to main screen
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo moved successfully')));
      // Pop back to the first screen (main screen) and replace it with a fresh instance
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error moving photo: $e';
        _isMoving = false;
      });
    }
  }
}

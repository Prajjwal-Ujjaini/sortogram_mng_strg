import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'album_photos_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Photo Albums'), elevation: 2),
        body: SafeArea(
          child: FutureBuilder<List<AssetPathEntity>>(
            future: PhotoManager.getAssetPathList(
              hasAll: false,
              type: RequestType.image,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No photo albums found'));
              }

              final albums = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: albums.length,
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return FutureBuilder<List<AssetEntity>>(
                    future: album.getAssetListRange(start: 0, end: 1),
                    builder: (context, previewSnapshot) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AlbumPhotosScreen(album: album),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              if (previewSnapshot.hasData &&
                                  previewSnapshot.data!.isNotEmpty)
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: AssetEntityImage(
                                    previewSnapshot.data!.first,
                                    isOriginal: false,
                                    thumbnailSize: const ThumbnailSize.square(
                                      200,
                                    ),
                                    thumbnailFormat: ThumbnailFormat.jpeg,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.photo_library),
                                ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      album.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<int>(
                                      future: album.assetCountAsync,
                                      builder: (context, snapshot) {
                                        return Text(
                                          '${snapshot.data ?? 0} photos',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _checkPermissions() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (!permitted.isAuth) {
      debugPrint('Permission denied. Auth status: ${permitted.isAuth}');
    }
  }
}

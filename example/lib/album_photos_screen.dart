import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'photo_details_screen.dart';

class AlbumPhotosScreen extends StatelessWidget {
  final AssetPathEntity album;

  const AlbumPhotosScreen({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(album.name)),
      body: SafeArea(
        child: FutureBuilder<List<AssetEntity>>(
          future: album.getAssetListRange(start: 0, end: 1000),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No photos in this album'));
            }

            final photos = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 1,
                crossAxisSpacing: 1,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoDetailsScreen(photo: photo),
                      ),
                    );
                  },
                  child: AssetEntityImage(
                    photo,
                    isOriginal: false,
                    thumbnailSize: const ThumbnailSize.square(200),
                    thumbnailFormat: ThumbnailFormat.jpeg,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

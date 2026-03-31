import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_colors.dart';
import '../providers/photo_providers.dart';
import '../../../database/app_database.dart';
import 'smart_camera_scanner.dart';

class PhotosTab extends ConsumerStatefulWidget {
  const PhotosTab({super.key});

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = p.join(appDir.path, fileName);

      await File(image.path).copy(savedPath);

      final dao = ref.read(photoDaoProvider);
      await dao.insertPhoto(
        ProgressPhotosCompanion.insert(
          imagePath: savedPath,
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add photo: $e')));
      }
    }
  }

  Future<void> _openSmartCamera() async {
    final photos = ref.read(progressPhotosProvider).valueOrNull ?? [];
    final latestPhoto = photos.isNotEmpty ? photos.first : null;

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => SmartCameraScanner(
          ghostImagePath: latestPhoto?.maskImagePath,
          referencePoseJson: latestPhoto?.poseDataJson,
        ),
      ),
    );

    if (result == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = p.join(appDir.path, fileName);

      await File(result['imagePath']).copy(savedPath);

      final dao = ref.read(photoDaoProvider);
      await dao.insertPhoto(
        ProgressPhotosCompanion.insert(
          imagePath: savedPath,
          createdAt: DateTime.now(),
          poseDataJson: drift.Value(result['poseDataJson']),
          maskImagePath: drift.Value(result['maskImagePath']),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save smart photo: $e')));
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: AppColors.primary),
                title: const Text('Smart Camera (Alignment)'),
                subtitle: const Text('Ghosting & skeleton tracking'),
                onTap: () {
                  Navigator.of(context).pop();
                  _openSmartCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Basic Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Photo Library'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceActionSheet,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Progress'),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(child: Text('No progress photos yet. Tap + to add.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photo.imagePath), fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black87, Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(photo.createdAt),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

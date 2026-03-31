import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_providers.dart';
import '../../../database/app_database.dart';

final photoDaoProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return db.photoDao;
});

final progressPhotosProvider = StreamProvider<List<ProgressPhoto>>((ref) {
  final dao = ref.watch(photoDaoProvider);
  return dao.watchAllPhotos();
});

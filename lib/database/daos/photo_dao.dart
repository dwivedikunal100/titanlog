import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/progress_photos.dart';

part 'photo_dao.g.dart';

@DriftAccessor(tables: [ProgressPhotos])
class PhotoDao extends DatabaseAccessor<AppDatabase> with _$PhotoDaoMixin {
  PhotoDao(super.db);

  Future<int> insertPhoto(ProgressPhotosCompanion entry) {
    return into(progressPhotos).insert(entry);
  }

  Stream<List<ProgressPhoto>> watchAllPhotos() {
    return (select(progressPhotos)
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<int> deletePhoto(int id) {
    return (delete(progressPhotos)..where((t) => t.id.equals(id))).go();
  }
}

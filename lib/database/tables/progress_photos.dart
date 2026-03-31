import 'package:drift/drift.dart';

@DataClassName('ProgressPhoto')
class ProgressPhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get imagePath => text()(); // Stores the local file path
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get notes => text().nullable()();
  RealColumn get bodyWeight => real().nullable()(); // Optional tracking feature
  
  // Storage for Ghost Image Mask overlay
  TextColumn get maskImagePath => text().nullable()();
  // JSON array backing for the Skeleton layout
  TextColumn get poseDataJson => text().nullable()();
}

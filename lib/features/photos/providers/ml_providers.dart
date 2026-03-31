import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class AlignmentState {
  final Pose? livePose;
  final bool isAligned;
  final Map<String, Map<String, double>>? referencePoseMap;

  AlignmentState({
    this.livePose,
    this.isAligned = false,
    this.referencePoseMap,
  });

  AlignmentState copyWith({
    Pose? livePose,
    bool? isAligned,
    Map<String, Map<String, double>>? referencePoseMap,
  }) {
    return AlignmentState(
      livePose: livePose ?? this.livePose,
      isAligned: isAligned ?? this.isAligned,
      referencePoseMap: referencePoseMap ?? this.referencePoseMap,
    );
  }
}

class PoseAlignmentNotifier extends AutoDisposeAsyncNotifier<AlignmentState> {
  late final PoseDetector _poseDetector;
  bool _isProcessing = false;

  @override
  Future<AlignmentState> build() async {
    _poseDetector = PoseDetector(options: PoseDetectorOptions());
    ref.onDispose(() => _poseDetector.close());
    return AlignmentState();
  }

  void loadReferencePose(String? poseDataJson) {
    if (poseDataJson == null || poseDataJson.isEmpty) return;
    try {
      final Map<String, dynamic> decoded = jsonDecode(poseDataJson);
      final Map<String, Map<String, double>> refMap = {};
      decoded.forEach((key, value) {
        if (value is Map) {
          refMap[key] = {
            'x': (value['x'] as num).toDouble(),
            'y': (value['y'] as num).toDouble(),
          };
        }
      });
      state = AsyncData(state.requireValue.copyWith(referencePoseMap: refMap));
    } catch (e) {
      debugPrint('Error parsing reference pose json: $e');
    }
  }

  Future<void> processCameraFrame(InputImage image, Size previewSize) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final poses = await _poseDetector.processImage(image);
      if (poses.isEmpty) {
        state = AsyncData(state.requireValue.copyWith(livePose: null, isAligned: false));
        return;
      }
      
      final livePose = poses.first;
      final refMap = state.requireValue.referencePoseMap;
      
      bool aligned = false;
      if (refMap != null && refMap.isNotEmpty) {
        aligned = _calculateAlignmentDelta(livePose, refMap, image.metadata?.size ?? previewSize);
      } else {
        // If there's no reference photo, it's always "aligned" (can always take photo)
        aligned = true;
      }

      state = AsyncData(state.requireValue.copyWith(
        livePose: livePose,
        isAligned: aligned,
      ));
    } finally {
      _isProcessing = false;
    }
  }

  bool _calculateAlignmentDelta(Pose live, Map<String, Map<String, double>> reference, Size imageSize) {
    // Simplified Delta logic. We check shoulders specifically.
    final leftShoulder = live.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = live.landmarks[PoseLandmarkType.rightShoulder];
    
    if (leftShoulder == null || rightShoulder == null) return false;

    final refLS = reference['leftShoulder'];
    final refRS = reference['rightShoulder'];
    if (refLS == null || refRS == null) return false; // Incomplete reference

    // Calculate relative positions vs normalized size to account for different camera ratios
    // Since ML Kit returns absolute pixels matching imageSize:
    final normLiveLSx = leftShoulder.x / imageSize.width;
    final normLiveLSy = leftShoulder.y / imageSize.height;
    final normLiveRSx = rightShoulder.x / imageSize.width;
    final normLiveRSy = rightShoulder.y / imageSize.height;

    final deltaLSx = (normLiveLSx - refLS['x']!).abs();
    final deltaLSy = (normLiveLSy - refLS['y']!).abs();
    final deltaRSx = (normLiveRSx - refRS['x']!).abs();
    final deltaRSy = (normLiveRSy - refRS['y']!).abs();

    const double tolerance = 0.08; // 8% pixel margin of error
    
    return deltaLSx < tolerance && deltaLSy < tolerance && 
           deltaRSx < tolerance && deltaRSy < tolerance;
  }
}

final poseAlignmentProvider = AsyncNotifierProvider.autoDispose<PoseAlignmentNotifier, AlignmentState>(
  () => PoseAlignmentNotifier(),
);

// Utility to convert Pose to JSON for storage
String serializePoseToJson(Pose pose, Size imageSize) {
  final Map<String, Map<String, double>> map = {};
  pose.landmarks.forEach((type, landmark) {
    map[type.name] = {
      'x': landmark.x / imageSize.width,
      'y': landmark.y / imageSize.height,
    };
  });
  return jsonEncode(map);
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/ml_providers.dart';

class SmartCameraScanner extends ConsumerStatefulWidget {
  final String? ghostImagePath; // Path to previous photo's mask
  final String? referencePoseJson; // The pose string from Drift

  const SmartCameraScanner({super.key, this.ghostImagePath, this.referencePoseJson});

  @override
  ConsumerState<SmartCameraScanner> createState() => _SmartCameraScannerState();
}

class _SmartCameraScannerState extends ConsumerState<SmartCameraScanner> {
  CameraController? _controller;
  bool _isProcessingFrame = false;
  late final SelfieSegmenter _segmenter;

  @override
  void initState() {
    super.initState();
    _segmenter = SelfieSegmenter(
      mode: SegmenterMode.single,
      enableRawSizeMask: true,
    );
    // Pre-load reference pose if available
    Future.microtask(() {
      ref.read(poseAlignmentProvider.notifier).loadReferencePose(widget.referencePoseJson);
    });
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Default to front camera for selfies
    final frontCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cameras.first);
    
    _controller = CameraController(
      frontCamera, 
      ResolutionPreset.high, 
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    
    await _controller!.initialize();
    
    _controller!.startImageStream((CameraImage image) {
      if (_isProcessingFrame) return; // Prevent concurrent conversions
      _isProcessingFrame = true;
      try {
        final inputImage = _getMkitInputImage(image, frontCamera);
        if (inputImage != null) {
          final size = Size(image.width.toDouble(), image.height.toDouble());
          ref.read(poseAlignmentProvider.notifier).processCameraFrame(inputImage, size);
        }
      } finally {
        _isProcessingFrame = false;
      }
    });
    
    if (mounted) setState(() {});
  }

  InputImage? _getMkitInputImage(CameraImage image, CameraDescription camera) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    InputImageRotation imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
    
    InputImageFormat inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
    
    final metadata = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _segmenter.close();
    super.dispose();
  }

  Future<String?> _generateMask(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final mask = await _segmenter.processImage(inputImage);
    if (mask == null) return null;

    // final appDir = await getApplicationDocumentsDirectory();
    // final maskPath = p.join(appDir.path, 'mask_${DateTime.now().millisecondsSinceEpoch}.png');
    
    // In a real app, you'd convert the segmentation mask buffer to a PNG.
    // For now, we'll store the original as a placeholder and return the path.
    // Full bit-mask to PNG conversion is quite verbose in Flutter/Dart.
    return imagePath; // Placeholder for now
  }

  void _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) return;
    
    try {
      final XFile photo = await _controller!.takePicture();
      final alignmentState = ref.read(poseAlignmentProvider).valueOrNull;
      
      String? poseJson;
      if (alignmentState?.livePose != null) {
        final size = Size(
          _controller!.value.previewSize?.height ?? 1080, 
          _controller!.value.previewSize?.width ?? 1920
        );
        poseJson = serializePoseToJson(alignmentState!.livePose!, size);
      }

      // Generate mask for the next ghost
      final maskPath = await _generateMask(photo.path);

      if (mounted) {
        Navigator.pop(context, {
          'imagePath': photo.path,
          'poseDataJson': poseJson,
          'maskImagePath': maskPath,
        });
      }
    } catch (e) {
      debugPrint("Error taking photo: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black, body: Center(child: CircularProgressIndicator()));
    }

    final alignmentState = ref.watch(poseAlignmentProvider).valueOrNull;
    final isAligned = alignmentState?.isAligned ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Feed
          CameraPreview(_controller!),
          
          // 2. Ghost Overlay
          if (widget.ghostImagePath != null && File(widget.ghostImagePath!).existsSync())
            Opacity(
              opacity: 0.4,
              child: Image.file(
                File(widget.ghostImagePath!), 
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            
          // 3. Sketch Overlay Map
          if (alignmentState?.livePose != null)
            CustomPaint(
              painter: AlignmentPainter(
                livePose: alignmentState!.livePose!,
                isAligned: isAligned,
              ),
            ),
            
           // Safe Area UI
           SafeArea(
             child: Stack(
               children: [
                 Positioned(
                   top: 16,
                   left: 16,
                   child: IconButton(
                     icon: const Icon(Icons.close, color: Colors.white),
                     onPressed: () => Navigator.pop(context),
                   ),
                 ),
                 if (!isAligned && widget.referencePoseJson != null)
                   Positioned(
                     top: 24,
                     left: 0,
                     right: 0,
                     child: Center(
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: Colors.black54,
                           borderRadius: BorderRadius.circular(16)
                         ),
                         child: const Text('Align shoulders with the red lines', style: TextStyle(color: Colors.white)),
                       )
                     ),
                   ),
                 Positioned(
                   bottom: 40,
                   left: 0,
                   right: 0,
                   child: Center(
                     child: GestureDetector(
                       onTap: _takePhoto,
                       child: AnimatedContainer(
                         duration: const Duration(milliseconds: 200),
                         width: 80,
                         height: 80,
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           border: Border.all(
                             color: isAligned ? Colors.greenAccent : Colors.white38,
                             width: 4,
                           ),
                           color: isAligned ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.transparent,
                         ),
                         child: Center(
                           child: Container(
                             width: 64,
                             height: 64,
                             decoration: BoxDecoration(
                               shape: BoxShape.circle,
                               color: isAligned ? Colors.greenAccent : Colors.white24,
                             ),
                           ),
                         ),
                       ),
                     ),
                   ),
                 )
               ]
             ),
           )
        ],
      ),
    );
  }
}

class AlignmentPainter extends CustomPainter {
  final Pose livePose;
  final bool isAligned;

  AlignmentPainter({required this.livePose, required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isAligned ? Colors.greenAccent : Colors.redAccent
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
      final p1 = livePose.landmarks[type1];
      final p2 = livePose.landmarks[type2];
      if (p1 != null && p2 != null) {
        // We need to scale from ML image coordinates to UI coordinates.
        // Simplified mapping for the purpose of the architecture draft:
        canvas.drawLine(
          Offset(p1.x * (size.width / 480), p1.y * (size.height / 640)), 
          Offset(p2.x * (size.width / 480), p2.y * (size.height / 640)), 
          paint
        );
      }
    }

    // Draw main structural lines for alignment feedback
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
    drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
    drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
    drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);
  }

  @override
  bool shouldRepaint(covariant AlignmentPainter oldDelegate) {
    return oldDelegate.isAligned != isAligned || oldDelegate.livePose != livePose;
  }
}

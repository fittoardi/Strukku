import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../scan/receipt_parser.dart';
import '../scan/scan_provider.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  CameraController? _camera;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Kamera tidak tersedia');
      final controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (mounted) setState(() => _camera = controller);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _capture() async {
    if (_busy || _camera == null) return;
    setState(() => _busy = true);
    try {
      final file = await _camera!.takePicture();
      await _process(file.path);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _busy = true);
    try {
      await _process(file.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _process(String path) async {
    final ocr = await ref.read(ocrServiceProvider).recognize(path);
    ref.read(scanTextProvider.notifier).state = ocr;
    final parsed = ReceiptParser.parse(ocr);
    if (!mounted) return;
    await context.push('/scan/review', extra: parsed);
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Struk')),
      body: _error != null
          ? Center(child: Text(_error!))
          : camera == null || !camera.value.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(fit: StackFit.expand, children: [
                  CameraPreview(camera),
                  Center(child: Container(width: 280, height: 420, decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 3)))),
                  if (_busy) const Center(child: CircularProgressIndicator()),
                ]),
      bottomNavigationBar: SafeArea(
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          IconButton(onPressed: _busy ? null : _pick, icon: const Icon(Icons.photo_library)),
          FloatingActionButton(onPressed: _busy ? null : _capture, child: const Icon(Icons.camera_alt)),
          IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.close)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }
}

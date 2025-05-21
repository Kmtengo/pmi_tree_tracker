import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CustomCameraScreen extends StatefulWidget {
  final Function(String) onImageCaptured;

  const CustomCameraScreen({
    super.key,
    required this.onImageCaptured,
  });

  @override
  State<CustomCameraScreen> createState() => _CustomCameraScreenState();
}

class _CustomCameraScreenState extends State<CustomCameraScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isReady = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentZoomLevel = 1.0;
  
  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      // Get available cameras
      cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        _showError('No cameras available');
        return;
      }
      
      // Initialize camera
      await _setupCamera(_selectedCameraIndex);
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    // Create controller
    _controller = CameraController(
      cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    // Initialize controller
    try {
      await _controller!.initialize();
      
      // Get zoom range
      await _controller!.getMinZoomLevel().then((value) {
        _minAvailableZoom = value;
      });
      
      await _controller!.getMaxZoomLevel().then((value) {
        _maxAvailableZoom = value;
      });
      
      setState(() {
        _isReady = true;
      });
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile photo = await _controller!.takePicture();
      
      if (mounted) {
        widget.onImageCaptured(photo.path);
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  void _switchCamera() {
    if (cameras.length <= 1) return;
    
    _selectedCameraIndex = (_selectedCameraIndex + 1) % cameras.length;
    _setupCamera(_selectedCameraIndex);
  }

  Widget _buildCameraOverlay() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
          ),
        ),
        // Transparent center rectangle
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.transparent,
            ),
            child: const Stack(
              children: [
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Position the tree within the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }    return Scaffold(
      backgroundColor: Colors.black,      appBar: AppBar(
        title: const Text('Take Photo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Camera preview
          SizedBox.expand(
            child: CameraPreview(_controller!),
          ),
          
          // Camera overlay
          _buildCameraOverlay(),
          
          // Zoom slider
          Positioned(
            right: 16,
            top: 60,
            child: RotatedBox(
              quarterTurns: 3,
              child: SizedBox(
                width: 250,
                child: Slider(
                  value: _currentZoomLevel,
                  min: _minAvailableZoom,
                  max: _maxAvailableZoom,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white30,
                  onChanged: (value) async {
                    setState(() {
                      _currentZoomLevel = value;
                    });
                    await _controller!.setZoomLevel(value);
                  },
                ),
              ),
            ),
          ),
          
          // Bottom controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _isCapturing ? null : _takePhoto,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: _isCapturing ? Colors.grey : Colors.white24,
                      ),
                      child: Center(
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Switch camera button
                  IconButton(
                    onPressed: cameras.length > 1 ? _switchCamera : null,
                    icon: Icon(
                      Icons.flip_camera_ios,
                      color: cameras.length > 1 ? Colors.white : Colors.grey,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

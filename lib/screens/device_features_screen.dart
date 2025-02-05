import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:battery_plus/battery_plus.dart';
import '../services/device_services.dart';
import 'photo_display_screen.dart';

class DeviceFeaturesScreen extends StatefulWidget {
  const DeviceFeaturesScreen({super.key});

  @override
  State<DeviceFeaturesScreen> createState() => _DeviceFeaturesScreenState();
}

class _DeviceFeaturesScreenState extends State<DeviceFeaturesScreen> {
  final DeviceServices _deviceServices = DeviceServices();
  Position? _currentPosition;
  String _batteryStatus = 'Unknown';
  int _batteryLevel = 0;
  bool _isCameraInitialized = false;
  late CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _initializeDevices();
  }

  Future<void> _initializeDevices() async {
    try {
      // Initialize camera
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
        );
        await _cameraController?.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }

      // Initialize battery status
      _batteryLevel = await _deviceServices.getBatteryLevel();
      if (mounted) {
        setState(() {});
      }

      // Listen to battery changes
      _deviceServices.getBatteryStateStream().listen((BatteryState state) {
        if (mounted) {
          setState(() {
            _batteryStatus = state.toString().split('.').last;
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing devices: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _deviceServices.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera is not initialized')),
      );
      return;
    }

    try {
      final XFile? image = await _cameraController!.takePicture();
      if (image != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoDisplayScreen(
              imagePath: image.path,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Features'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Preview Section
            if (_isCameraInitialized && _cameraController != null)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CameraPreview(_cameraController!),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isCameraInitialized ? _takePicture : null,
              child: const Text('Take Picture'),
            ),
            const SizedBox(height: 24),

            // Location Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_currentPosition != null)
                      Text(
                        'Lat: ${_currentPosition?.latitude.toStringAsFixed(4)}\nLong: ${_currentPosition?.longitude.toStringAsFixed(4)}',
                      ),
                    ElevatedButton(
                      onPressed: _getCurrentLocation,
                      child: const Text('Get Current Location'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Battery Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Battery',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Battery Level: $_batteryLevel%'),
                    if (_batteryStatus != 'Unknown')
                      Text('Status: $_batteryStatus'),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _batteryLevel / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _batteryLevel > 20 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

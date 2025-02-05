import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

class DeviceServices {
  static final DeviceServices _instance = DeviceServices._internal();
  factory DeviceServices() => _instance;
  DeviceServices._internal();

  final Battery _battery = Battery();

  // Geolocation Methods
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return Future.error('Location services are disabled.');
      }

      // Check location permissions
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied');
      }

      // Get current position
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Error getting location: $e');
      return Future.error('Failed to get location: $e');
    }
  }

  // Battery Methods
  Stream<BatteryState> getBatteryStateStream() {
    return _battery.onBatteryStateChanged;
  }

  Future<int> getBatteryLevel() async {
    try {
      final level = await _battery.batteryLevel;
      return level;
    } catch (e) {
      debugPrint('Error getting battery level: $e');
      return 0;
    }
  }
}

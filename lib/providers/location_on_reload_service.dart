import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

  bool hasPermission = false;

    Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      hasPermission = false;
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        hasPermission = false;
        return false;
      }
    }

  if (permission == LocationPermission.deniedForever) {
      hasPermission = false;
      return false;
    }
    hasPermission = true;
    return true;
  }

  Future<void> getCurrentPosition() async {
    hasPermission = await _handleLocationPermission();
    var _currentPosition;

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      _currentPosition = position;
    }).catchError((e) {
      debugPrint(e);
    }
  );
    final saveLocation = await SharedPreferences.getInstance();
    saveLocation.setStringList('savedLocation', [jsonEncode(_currentPosition)]);
  }

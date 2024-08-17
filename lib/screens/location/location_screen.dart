import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/widgets/address_search_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key, required this.isCreation});

  final bool isCreation;

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  String? _currentAddress;
  Position? _currentPosition;
  double _preferredRadius = 10.0;
  TextEditingController manualLocation = TextEditingController();
  var hasPermission = false;
  ScrollController scrollController = ScrollController();

  Future<void> getExistingLocation() async {
    final getLocation = await SharedPreferences.getInstance();
    final exsistingLocation = getLocation.getStringList('savedLocation');
    final setRadius = getLocation.getStringList('savedRadius');

    if (exsistingLocation != null) {
      setState(() {
        _currentPosition = Position.fromMap(json.decode(exsistingLocation[0]));
        _getAddressFromLatLng(_currentPosition!);
        _preferredRadius = double.parse(setRadius!.first);
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Location services are disabled. Please enable the services')));
      hasPermission = false;
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permissions are denied')));
        setState(() {
          hasPermission = false;
        });
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.')));
      setState(() {
        hasPermission = false;
      });
      return false;
    }
    setState(() {
      hasPermission = true;
    });
    return true;
  }

  Future<void> _getCurrentPosition() async {
    hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
    final saveLocation = await SharedPreferences.getInstance();
    saveLocation.setStringList('savedLocation', [jsonEncode(_currentPosition)]);
    _getAddressFromLatLng(Position.fromMap(json.decode(saveLocation.getStringList('savedLocation')![0])));
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(_currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress = '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  void initState() {
    super.initState();
    getExistingLocation();
    _handleLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndNavigate();
    });
  }

  void _checkAndNavigate() {
    if ((_currentAddress != null) && (!widget.isCreation)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const NavBar()),
      );
    }
  }

  Future<void> _setLocationManually() async {
    if (manualLocation.text.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(manualLocation.text);
        if (locations.isNotEmpty) {
          _currentPosition = Position(
              latitude: locations.first.latitude,
              longitude: locations.first.longitude,
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0);

          final saveLocation = await SharedPreferences.getInstance();
          saveLocation.setStringList('savedLocation', [jsonEncode(_currentPosition)]);
          _getAddressFromLatLng(_currentPosition!);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error finding address')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // if ((_currentAddress != null) && (!widget.isCreation)) {
    //                   Navigator.of(context).pushReplacement(
    //                     MaterialPageRoute(builder: (context) => const NavBar()),
    //                   );
    //                 }
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: Text(
          'Set Your Location',
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Location',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * .028,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We use your location to show events in your local community.',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * .018,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        scrollController.animateTo(100, duration: Duration(milliseconds: 200), curve: Curves.easeIn);
                        _getCurrentPosition;
                      },
                      icon: Icon(Icons.my_location),
                      label: Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Or enter location manually:',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * .018,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(height: 8),
                    AddressSearchField(
                      controller: manualLocation,
                      isEvent: false,
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        _setLocationManually();
                        scrollController.animateTo(100, duration: Duration(milliseconds: 200), curve: Curves.easeIn);
                      },
                      icon: Icon(Icons.edit_location),
                      label: Text('Set Manual Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Event Range',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * .028,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose the maximum distance for events you want to see:',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height * .018,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_preferredRadius.round()}',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'miles',
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _preferredRadius,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (double value) async {
                        setState(() {
                          _preferredRadius = value;
                        });
                        final saveRadius = await SharedPreferences.getInstance();
                        await saveRadius.setStringList('savedRadius', [value.toString()]);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            if (_currentAddress != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Saved Address:',
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.height * .028,
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _currentAddress ?? "",
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_currentPosition != null || manualLocation.text.isNotEmpty)
                  ? () async {
                      final saveRadius = await SharedPreferences.getInstance();
                      saveRadius.setStringList('savedRadius', [_preferredRadius.toString()]);
                      ref.read(eventsProvider.notifier).deCodeData();
                      if (widget.isCreation) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const NavBar()),
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
              child: Text(widget.isCreation ? 'See Events' : 'Save Location Data'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

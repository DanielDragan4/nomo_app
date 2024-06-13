import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/widgets/address_search_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({super.key, required this.isCreation});

  final bool isCreation;

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  String? _currentAddress;
  Position? _currentPosition;
  double _preferredRadius = 10.0;
  TextEditingController manualLocation = TextEditingController();
  var hasPermission = false;

  Future<void> getExsistingLocation() async {
    final getLocation = await SharedPreferences.getInstance();
    final exsistingLocation = getLocation.getStringList('savedLocation');
    final setRadius = getLocation.getStringList('savedRadius');
    print(setRadius);

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      hasPermission = false;
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        setState(() {
          hasPermission = false;
        });
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
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
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
    final saveLocation = await SharedPreferences.getInstance();
    saveLocation.setStringList('savedLocation', [jsonEncode(_currentPosition)]);
    _getAddressFromLatLng(Position.fromMap(
        json.decode(saveLocation.getStringList('savedLocation')![0])));
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  @override
  void initState() {
    getExsistingLocation();
    _handleLocationPermission();
    super.initState();
  }

  Future<void> _setLocationManually() async {
    if (manualLocation.text.isNotEmpty) {
      try {
        List<Location> locations =
            await locationFromAddress(manualLocation.text);
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
            headingAccuracy: 0.0
          );

          final saveLocation = await SharedPreferences.getInstance();
          saveLocation.setStringList(
              'savedLocation', [jsonEncode(_currentPosition)]);
          _getAddressFromLatLng(_currentPosition!);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error finding address')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Theme.of(context).canvasColor,
              floating: true,
              snap: true,
              expandedHeight: 10,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.all(0),
                background: Padding(
                  padding: const EdgeInsets.only(top: 35),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'Location',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          body: ListView(children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'We use your location to show you events in your local community!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      color: Theme.of(context).colorScheme.onSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _getCurrentPosition,
                  child: const Text('Get Current Location'),
                ),
                const SizedBox(height: 10),
                (!hasPermission)
                    ? AddressSearchField(controller: manualLocation)
                    : const SizedBox(),
                SizedBox(height: MediaQuery.of(context).size.height * .2),
                Text(
                  'Select a Radius for your Events',
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSecondary),
                ),
                Slider(
                  value: _preferredRadius,
                  min: 1,
                  max: 50,
                  divisions: 99,
                  label: '${_preferredRadius.round()} miles',
                  onChanged: (double value) {
                    setState(() {
                      _preferredRadius = value;
                    });
                  },
                ),
                (_currentAddress != null)
                    ? Text(
                        'Current Saved Address: ${_currentAddress ?? ""}',
                        style: TextStyle(
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSecondary),
                      )
                    : const Text(''),
                SizedBox(height: MediaQuery.of(context).size.height * .05),
                widget.isCreation
                    ? ElevatedButton(
                        onPressed: () {
                          // Logic to show events based on location or manually entered community
                        },
                        child: TextButton(
                          onPressed: (_currentPosition != null)
                              ? () async {
                                  final saveRadius =
                                      await SharedPreferences.getInstance();
                                  saveRadius.setStringList('savedRadius',
                                      [_preferredRadius.toString()]);
                                  Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const NavBar()));
                                }
                              : null,
                          child: const Text('See Events'),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () {},
                        child: TextButton(
                          child: const Text('Save Location Data'),
                          onPressed: () async {
                            final saveRadius =
                                await SharedPreferences.getInstance();
                            if (manualLocation.text.isNotEmpty) {
                              await _setLocationManually();
                            }
                            saveRadius.setStringList(
                                'savedRadius', [_preferredRadius.toString()]);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:nomo/providers/location-providers/nominatim_service.dart';

class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;
  final bool isEvent;
  final bool hasError;
  final bool isVirtual;
  final ValueChanged<String>? onChanged;

  const AddressSearchField({
    Key? key,
    required this.controller,
    required this.isEvent,
    this.hasError = false,
    this.isVirtual = false,
    this.onChanged,
  }) : super(key: key);

  @override
  _AddressSearchFieldState createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final RadarAutocompleteService _nominatimService = RadarAutocompleteService();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchLocation(String query) async {
    final country = await getSavedCountry();
    final results = await _nominatimService.autocomplete(query, country: country);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          enabled: !widget.isVirtual,
          controller: widget.controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderSide: BorderSide(color: widget.hasError ? Colors.red : Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.hasError ? Colors.red : Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.hasError ? Colors.red : Theme.of(context).colorScheme.primary),
            ),
            labelText: (widget.isEvent) ? "Enter The Event's Address" : "Enter Your Location",
            labelStyle: TextStyle(
              color: widget.hasError ? Colors.red : Theme.of(context).colorScheme.onSecondary,
            ),
            contentPadding: const EdgeInsets.all(5),
            errorText: widget.hasError ? "Location is required" : null,
          ),
          onChanged: (value) {
            widget.onChanged?.call(value);
            if (value.length > 3) {
              _searchLocation(value);
            } else {
              setState(() {
                _searchResults = [];
              });
            }
          },
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final result = _searchResults[index];
            return ListTile(
              title: Text(
                result['display_name'],
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
              onTap: () {
                setState(() {
                  widget.controller.text = result['display_name'];
                  _searchResults = [];
                });
                widget.onChanged?.call(result['display_name']);
              },
            );
          },
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * .025,
        )
      ],
    );
  }
}

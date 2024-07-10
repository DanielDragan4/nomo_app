import 'package:flutter/material.dart';
import 'package:nomo/providers/nominatim_service.dart';

class AddressSearchField extends StatefulWidget {
  final TextEditingController controller;

  const AddressSearchField({super.key, required this.controller, required this.isEvent});

  final bool isEvent;

  @override
  _AddressSearchFieldState createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  final NominatimService _nominatimService = NominatimService();
  List<Map<String, dynamic>> _searchResults = [];

  Future<void> _searchLocation(String query) async {
    final country = await getSavedCountry();
    final results = await _nominatimService.search(query, country: country);
    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
          decoration: InputDecoration(
            border: const  OutlineInputBorder(),
            labelText: (widget.isEvent) ?"Enter The Event's Address" : "Enter Your Location",
            labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            contentPadding: const EdgeInsets.all(5),
          ),
          onChanged: (value) {
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
              title: Text(result['display_name'],
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),),
              onTap: () {
                setState(() {
                  widget.controller.text = result['display_name'];
                  _searchResults = [];
                });
              },
            );
          },
        ),
        SizedBox(height: MediaQuery.of(context).size.height *.025,)
      ],
    );
  }
}

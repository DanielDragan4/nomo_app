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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context)!.insert(_overlayEntry!);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 4.0,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: ListView.builder(
                padding: EdgeInsets.zero,
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
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchLocation(String query) async {
    final country = await getSavedCountry();
    final results = await _nominatimService.autocomplete(query, country: country);
    setState(() {
      _searchResults = results;
      if (results.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        focusNode: _focusNode,
        enabled: !widget.isVirtual,
        controller: widget.controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.secondary,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: widget.hasError ? Colors.red : Theme.of(context).colorScheme.secondary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: widget.hasError ? Colors.red : Theme.of(context).colorScheme.secondary,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          labelText: (widget.isEvent) ? null : "Enter Your Location",
          labelStyle: TextStyle(
            color: widget.hasError ? Colors.red : Theme.of(context).colorScheme.onSecondary,
          ),
          contentPadding: const EdgeInsets.all(5),
          errorText: widget.hasError ? "Location is required" : null,
          hintText: (widget.isEvent) ? 'Enter event location' : null,
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        onChanged: (value) {
          widget.onChanged?.call(value);
          if (value.length > 3) {
            _searchLocation(value);
          } else {
            setState(() {
              _searchResults = [];
              _removeOverlay();
            });
          }
        },
      ),
    );
  }
}

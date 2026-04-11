/// CYKEL — Reusable Address Autocomplete Field
/// A text field with Google Places autocomplete for address entry.
/// Extracts coordinates and populates city/postal code fields automatically.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:async';

import '../../../../core/config/app_config.dart';

/// Callback when an address is selected with full details
typedef OnAddressSelected = void Function({
  required String street,
  required String city,
  required String postalCode,
  required double latitude,
  required double longitude,
});

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.streetController,
    this.cityController,
    this.postalController,
    this.onAddressSelected,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.enabled = true,
  });

  final TextEditingController streetController;
  final TextEditingController? cityController;
  final TextEditingController? postalController;
  final OnAddressSelected? onAddressSelected;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final _dio = Dio();
  Timer? _debounce;
  List<_PlacePrediction> _predictions = [];
  bool _showPredictions = false;
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Delay removal to allow tap on suggestion to register
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onAddressChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (value.length < 3) {
      _removeOverlay();
      setState(() {
        _predictions = [];
        _showPredictions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _fetchPlacePredictions(value);
    });
  }

  Future<void> _fetchPlacePredictions(String input) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': input,
          'key': AppConfig.googleMapsApiKey,
          'components': 'country:dk', // Denmark only
          'types': 'address',
          'language': 'da', // Danish results for better local address matching
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final predictions = (response.data['predictions'] as List)
            .map((p) => _PlacePrediction.fromJson(p))
            .toList();

        if (mounted) {
          setState(() {
            _predictions = predictions;
            _showPredictions = predictions.isNotEmpty;
          });

          if (predictions.isNotEmpty) {
            _showOverlay();
          } else {
            _removeOverlay();
          }
        }
      } else {
        _removeOverlay();
      }
    } catch (e) {
      debugPrint('Places autocomplete error: $e');
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A7C59).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 18,
                          color: Color(0xFF4A7C59),
                        ),
                      ),
                      title: Text(
                        prediction.mainText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: prediction.secondaryText != null
                          ? Text(
                              prediction.secondaryText!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            )
                          : null,
                      onTap: () => _selectPlace(prediction),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> _selectPlace(_PlacePrediction prediction) async {
    _removeOverlay();
    FocusScope.of(context).unfocus();

    try {
      // Get place details to extract address components AND COORDINATES
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': prediction.placeId,
          'key': AppConfig.googleMapsApiKey,
          'fields': 'address_components,formatted_address,geometry',
          'language': 'da',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['result'];
        final components = result['address_components'] as List;

        // Extract coordinates
        double latitude = 0;
        double longitude = 0;
        final geometry = result['geometry'];
        if (geometry != null && geometry['location'] != null) {
          final location = geometry['location'];
          latitude = (location['lat'] as num).toDouble();
          longitude = (location['lng'] as num).toDouble();
        }

        String? street;
        String? streetNumber;
        String? city;
        String? postalCode;

        for (var component in components) {
          final types = component['types'] as List;

          if (types.contains('route')) {
            street = component['long_name'];
          }
          if (types.contains('street_number')) {
            streetNumber = component['long_name'];
          }
          if (types.contains('locality') || types.contains('postal_town')) {
            city = component['long_name'];
          }
          if (types.contains('postal_code')) {
            postalCode = component['long_name'];
          }
        }

        // Format street address with number
        String formattedStreet;
        if (street != null && streetNumber != null) {
          formattedStreet = '$street $streetNumber';
        } else if (street != null) {
          formattedStreet = street;
        } else {
          formattedStreet = prediction.mainText;
        }

        // Update controllers
        widget.streetController.text = formattedStreet;
        if (city != null) widget.cityController?.text = city;
        if (postalCode != null) widget.postalController?.text = postalCode;

        // Notify callback with all details
        widget.onAddressSelected?.call(
          street: formattedStreet,
          city: city ?? '',
          postalCode: postalCode ?? '',
          latitude: latitude,
          longitude: longitude,
        );
      }
    } catch (e) {
      debugPrint('Place details error: $e');
      // Fallback: just use the main text
      widget.streetController.text = prediction.mainText;
    }

    if (mounted) {
      setState(() {
        _predictions = [];
        _showPredictions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.streetController,
        focusNode: _focusNode,
        enabled: widget.enabled,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: widget.labelText ?? 'Street Address',
          hintText: widget.hintText ?? 'Start typing to search...',
          prefixIcon: Icon(widget.prefixIcon ?? Icons.location_on_outlined),
          suffixIcon: _showPredictions || widget.streetController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    widget.streetController.clear();
                    _removeOverlay();
                    setState(() {
                      _predictions = [];
                      _showPredictions = false;
                    });
                  },
                )
              : null,
        ),
        onChanged: _onAddressChanged,
        onTap: () {
          if (_predictions.isNotEmpty) {
            _showOverlay();
          }
        },
        validator: widget.validator,
      ),
    );
  }
}

// ─── Place Prediction Model ──────────────────────────────────────────────────

class _PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  _PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });

  factory _PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] ?? {};

    return _PlacePrediction(
      placeId: json['place_id'] ?? '',
      description: json['description'] ?? '',
      mainText: structuredFormatting['main_text'] ?? json['description'] ?? '',
      secondaryText: structuredFormatting['secondary_text'],
    );
  }
}

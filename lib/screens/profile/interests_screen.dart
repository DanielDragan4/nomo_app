import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/supabase-providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase-providers/user_signup_provider.dart';
import 'package:nomo/screens/location/location_screen.dart';

class InterestsScreen extends ConsumerStatefulWidget {
  InterestsScreen(
      {super.key,
      required this.isEditing,
      this.creatingEvent,
      this.searching,
      this.selectedInterests,
      this.onSelectionChanged});

  bool isEditing;
  bool? creatingEvent;
  bool? searching;
  Map<Interests, bool>? selectedInterests = {};
  final Function(Map<Interests, bool>)? onSelectionChanged;

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late Map<Interests, bool> _selectedOptions = {for (var option in Interests.values) option: false};
  late int _selectedCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _isLoading = true;
      initializeSelectedOptions().then((_) {
        setState(() => _isLoading = false);
      });
    } else if (widget.creatingEvent != null && widget.selectedInterests!.isNotEmpty) {
      _selectedOptions = widget.selectedInterests!;
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    } else {
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    }
  }

  Future<void> initializeSelectedOptions() async {
    final existingInterests = await ref.read(profileProvider.notifier).fetchExistingInterests();

    _selectedOptions = {
      for (var option in Interests.values) option: existingInterests.contains(option.value),
    };

    _selectedCount = _selectedOptions.values.where((value) => value).length;
  }

  void _handleInterestSelection(Interests interest) {
    if (widget.isEditing || (!widget.isEditing && _selectedCount < 5) || _selectedOptions[interest] == true) {
      setState(() {
        _selectedOptions[interest] = !_selectedOptions[interest]!;
        _selectedCount = _selectedOptions.values.where((value) => value).length;

        if (widget.onSelectionChanged != null) {
          widget.onSelectionChanged!(_selectedOptions);
        }
      });
    } else {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You can only select up to 5 options. You can edit these later."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: widget.searching == null
          ? AppBar(
              centerTitle: true,
              title: _buildHeader(colorScheme),
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.creatingEvent == null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Select up to 5 of your interests",
                      style: TextStyle(fontSize: 18, color: colorScheme.onBackground.withOpacity(0.7)),
                    ),
                  ),
                ),
              //widget.searching == null ? const SizedBox(height: 24) : const SizedBox.shrink(),
              Expanded(child: _buildInterestGrid()),
              //if (widget.searching == null) const SizedBox(height: 16),
              if (widget.searching == null) _buildBottomActions(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Column(
        children: [
          Text(
            widget.creatingEvent == null ? 'Interests' : 'Event Categories',
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestGrid() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Wrap(
        spacing: 10.0, // horizontal spacing between items
        runSpacing: 5.0, // vertical spacing between lines
        children: Interests.values.map((interest) => _buildInterestItem(interest)).toList(),
      ),
    );
  }

  Widget _buildInterestItem(Interests option) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedOptions[option] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: IntrinsicWidth(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.surface,
            foregroundColor: colorScheme.onSurface,
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline,
                width: isSelected ? 3 : 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          ),
          onPressed: () => _handleInterestSelection(option),
          child: Text(
            option.value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: colorScheme.onSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _handleContinueButton,
            child: Text(
              _getContinueButtonText(),
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSecondary),
            ),
          ),
        ),
        if (!widget.isEditing && widget.creatingEvent == null)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: TextButton(
              onPressed: _handleSkipButton,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Skip", style: TextStyle(fontSize: 16)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _getContinueButtonText() {
    if (!widget.isEditing) {
      return widget.creatingEvent == null ? "Continue" : "Add Interests";
    }
    return "Update";
  }

  void _handleContinueButton() async {
    if (widget.creatingEvent == null) {
      await ref.watch(profileProvider.notifier).updateInterests(_selectedOptions);
      if (!widget.isEditing) {
        if (widget.creatingEvent == null) {
          ref.read(onSignUp.notifier).completeProfileCreation();
          ref.read(savedSessionProvider.notifier).changeSessionDataList();

          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) => const LocationScreen(isCreation: true)));
        }
      } else {
        Navigator.of(context).pop();
      }
    } else {
      print(_selectedOptions);
      Navigator.pop(context, _selectedOptions);
    }
  }

  void _handleSkipButton() {
    if (widget.creatingEvent == null) {
      ref.watch(profileProvider.notifier).skipInterests();
      ref.read(onSignUp.notifier).completeProfileCreation();
      ref.read(savedSessionProvider.notifier).changeSessionDataList();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const NavBar()));
    }
  }
}

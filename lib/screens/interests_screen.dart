import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/screens/location_test_screen.dart';

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
  late Map<Interests, bool> _selectedOptions = {
    for (var option in Interests.values) option: false
  };
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
    } else if (widget.creatingEvent != null &&
        widget.selectedInterests!.isNotEmpty) {
      _selectedOptions = widget.selectedInterests!;
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    } else {
      _selectedCount = _selectedOptions.values.where((value) => value).length;
    }
  }

  Future<void> initializeSelectedOptions() async {
    final existingInterests =
        await ref.read(profileProvider.notifier).fetchExistingInterests();

    _selectedOptions = {
      for (var option in Interests.values)
        option: existingInterests.contains(ref
            .read(profileProvider.notifier)
            .enumToString(option.toString().split('.')[1])),
    };

    _selectedCount = _selectedOptions.values.where((value) => value).length;
  }

  void _handleInterestSelection(Interests interest) {
    if (widget.isEditing ||
        (!widget.isEditing && _selectedCount < 5) ||
        _selectedOptions[interest] == true) {
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
          content: Text(
              "You can only select up to 5 options. You can edit these later."),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: widget.searching == false
          ? AppBar(centerTitle: true, title: _buildHeader(colorScheme))
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Expanded(child: _buildInterestGrid()),
              if (widget.searching == false) const SizedBox(height: 16),
              if (widget.searching == false) _buildBottomActions(colorScheme),
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
          if (widget.creatingEvent != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "Select up to 5 of your interests",
                style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onBackground.withOpacity(0.7)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInterestGrid() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 2.2,
      ),
      itemCount: Interests.values.length,
      itemBuilder: (context, index) =>
          _buildInterestItem(Interests.values[index]),
    );
  }

  Widget _buildInterestItem(Interests option) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedOptions[option] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? colorScheme.primary : colorScheme.surface,
          foregroundColor:
              isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
        onPressed: () => _handleInterestSelection(option),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ref.read(profileProvider.notifier).enumToString(option),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(ColorScheme colorScheme) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: _handleContinueButton,
          child: Text(
            _getContinueButtonText(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
      await ref
          .watch(profileProvider.notifier)
          .updateInterests(_selectedOptions);
      if (!widget.isEditing) {
        if (widget.creatingEvent == null) {
          ref.read(onSignUp.notifier).completeProfileCreation();
          ref.read(savedSessionProvider.notifier).changeSessionDataList();

          Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) =>
                  const LocationTestScreen(isCreation: true)));
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
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const NavBar()));
    }
  }
}

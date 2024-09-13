import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/profile/create_account_screen.dart'; // Ensure this import is correct

class UniversityScreen extends ConsumerStatefulWidget {
  const UniversityScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UniversityScreen> createState() => _UniversityScreenState();
}

class _UniversityScreenState extends ConsumerState<UniversityScreen> {
  String? selectedUniversity;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text(
              'Select Your University',
              style: TextStyle(
                color: Theme.of(context).primaryColorLight,
                fontWeight: FontWeight.w800,
                fontSize: 25,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildUniversityButton(
                        'Rutgers - New Brunswick',
                        'assets/images/RutgersLogo.png',
                        'rutgers',
                      ),
                    ),
                    SizedBox(width: MediaQuery.of(context).size.width / 24),
                    Expanded(
                      child: _buildUniversityButton(
                        'NJIT',
                        'assets/images/NJITLogo.png',
                        'njit',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              child: ElevatedButton(
                onPressed: selectedUniversity != null ? () => _navigateToCreateAccount() : null,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary),
                child: Text('Continue', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUniversityButton(String name, String logoPath, String value) {
    final isSelected = selectedUniversity == value;
    return GestureDetector(
      onTap: () => setState(() => selectedUniversity = value),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              logoPath,
              height: MediaQuery.of(context).size.width / 8,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateAccount() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CreateAccountScreen(
          isNew: true,
          university: selectedUniversity,
        ),
      ),
    );
  }
}

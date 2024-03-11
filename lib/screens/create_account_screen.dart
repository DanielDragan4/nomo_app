import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';
import 'package:nomo/models/place.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:uuid/uuid.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() {
    return _CreateAccountScreenState();
  }
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: Column(
        children: [
          Text("Create Account"),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(200)),
            child: ImageInput(
              onPickImage: (image) {
                _selectedImage = image;
              },
            ),
          )
        ],
      ),
    );
  }
}

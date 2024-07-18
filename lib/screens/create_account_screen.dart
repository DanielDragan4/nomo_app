import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomo/functions/make-fcm.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/interests_screen.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:postgrest/src/types.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

class CreateAccountScreen extends ConsumerStatefulWidget {
  CreateAccountScreen(
      {super.key, required this.isNew, this.avatar, this.profilename, this.username, this.onUpdateProfile});

  bool isNew;
  final String? avatar;
  final String? username;
  final String? profilename;
  final VoidCallback? onUpdateProfile;

  @override
  ConsumerState<CreateAccountScreen> createState() {
    return _CreateAccountScreenState();
  }
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  File? _selectedImage;
  double radius = 75;
  final _profileName = TextEditingController();
  final _userName = TextEditingController();
  final _phoneNum = TextEditingController();
  String? avatar;

  @override
  void initState() {
    if (!widget.isNew) {
      avatar = widget.avatar!;
      _profileName.text = widget.profilename!;
      _userName.text = widget.username!;
    }
    super.initState();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  dynamic uploadAvatar(File? imageFile) async {
    final supabase = (await ref.read(supabaseInstance));
    final userId = supabase.client.auth.currentUser!.id.toString();
    PostgrestList imgId;

    var uuid = const Uuid();
    final currentImageName = uuid.v4();

    if (imageFile != null) {
      // Read the file
      Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode the image
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage != null) {
        // Resize the image
        img.Image resizedImage =
            img.copyResize(originalImage, width: 150, height: 150, interpolation: img.Interpolation.linear);

        // Encode the image to PNG
        List<int> resizedImageBytes = img.encodePng(resizedImage);

        // Create a temporary file with the resized image
        File tempFile = await File('${Directory.systemTemp.path}/resized_$currentImageName.png').create();
        await tempFile.writeAsBytes(resizedImageBytes);

        // Upload the resized image
        final response =
            await supabase.client.storage.from('Images').upload('$userId/avatar/$currentImageName', tempFile);

        // Delete the temporary file
        await tempFile.delete();

        imgId = await supabase.client
            .from('Images')
            .insert({'image_url': '$userId/avatar/$currentImageName'}).select('images_id');
      } else {
        // Handle error: unable to decode image
        throw Exception('Unable to decode image');
      }
    } else {
      imgId =
          await supabase.client.from('Images').insert({'image_url': 'default/avatar/sadboi.png'}).select('images_id');
    }
    return imgId[0]["images_id"];
  }

  Future _createProfile(String user, File? selectedImage) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    var avatarId = await uploadAvatar(selectedImage);

    if (user.replaceAll(' ', '') == '') {
      user = 'User-${supabase.auth.currentUser!.id.replaceAll('-', '').substring(0, 10)}';
      if (_profileName.text.replaceAll(' ', '') == '') {
        _profileName.text = user;
      }
    }

    final newProfileRowMap = {
      'profile_id': supabase.auth.currentUser!.id,
      'avatar_id': avatarId,
      'username': user,
      'profile_name': _profileName.text,
      'private': false
    };

    if (_profileName.text.replaceAll(' ', '') != '') {
      newProfileRowMap['profile_name'] = _profileName.text;
    }
    if (widget.isNew) {
      await supabase.from('Profiles').insert(newProfileRowMap);
      await makeFcm(supabase);
    } else {
      await supabase.from('Profiles').update(
        {'avatar_id': avatarId, 'username': user, 'profile_name': _profileName.text},
      ).eq('profile_id', newProfileRowMap['profile_id']);
    }
  }

  //TODO: delete previous avatar to save space
  Future<void> _updateProfile() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    var avatarId = _selectedImage != null
        ? await uploadAvatar(_selectedImage)
        : await supabase
            .from('Profiles')
            .select('avatar_id')
            .eq('profile_id', supabase.auth.currentUser!.id)
            .single()
            .then((response) => response['avatar_id'] as String?);
    var user = _userName.text;
    final userId = supabase.auth.currentUser!.id.toString();

    if (_selectedImage != null) {
      await supabase.storage.from('Images').remove(['$userId/avatar/$avatar']);
    }

    if (user.replaceAll(' ', '') == '') {
      user = 'User-${supabase.auth.currentUser!.id.replaceAll('-', '').substring(0, 10)}';
    }
    final updateProfileRowMap = {'avatar_id': avatarId, 'username': user, 'profile_name': _profileName.text};

    await supabase.from('Profiles').update(updateProfileRowMap).eq('profile_id', supabase.auth.currentUser!.id);

    // Update local state
    await ref.read(profileProvider.notifier).updateProfileLocally(
          _userName.text,
          _profileName.text,
          avatarId,
        );
    widget.onUpdateProfile?.call();
    //if (mounted) Navigator.of(context).pop();
  }

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
            child: Text(widget.isNew ? 'Create Profile' : 'Update Profile',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                )),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            widget.isNew
                ? const Padding(
                    padding: EdgeInsets.only(left: 12.0),
                    child: Text(
                      "Create Account",
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (BuildContext context) {
                      // Get screen size
                      final screenSize = MediaQuery.of(context).size;
                      final double fontSize = screenSize.width * 0.04; // 4% of screen width for font size

                      return Container(
                        width: double.infinity, // Ensures full width
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.05,
                              vertical: screenSize.height * 0.03,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches buttons to full width
                              children: [
                                TextButton(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Select from Gallery",
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                      SizedBox(width: screenSize.width * 0.01),
                                      const Icon(Icons.photo_library_rounded)
                                    ],
                                  ),
                                  onPressed: () {
                                    _pickImageFromGallery();
                                    Navigator.pop(context);
                                  },
                                ),
                                const Divider(),
                                SizedBox(height: screenSize.height * 0.01),
                                TextButton(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Take a Picture",
                                        style: TextStyle(fontSize: fontSize),
                                      ),
                                      SizedBox(width: screenSize.width * 0.01),
                                      const Icon(Icons.camera_alt_rounded)
                                    ],
                                  ),
                                  onPressed: () {
                                    _pickImageFromCamera();
                                    Navigator.pop(context);
                                  },
                                ),
                                const Divider(),
                                SizedBox(height: screenSize.height * 0.005),
                                TextButton(
                                  child: Text(
                                    "Close",
                                    style: TextStyle(fontSize: fontSize),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                child: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                  radius: radius,
                  child: CircleAvatar(
                    radius: radius - 2,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!)
                        : (avatar != null ? NetworkImage(avatar!) as ImageProvider : null),
                    child: _selectedImage == null && avatar == null
                        ? Container(
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  Color.fromARGB(255, 63, 53, 78),
                                  Color.fromARGB(255, 112, 9, 167),
                                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(radius - 2)),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 15),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 15,
                controller: _profileName,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 15,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                controller: _userName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 11,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                controller: _phoneNum,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Phone Number",
                  contentPadding: EdgeInsets.all(5),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: ElevatedButton(
                child: widget.isNew ? const Text("Create Account") : const Text("Update"),
                onPressed: () async {
                  if (widget.isNew) {
                    await _createProfile(_userName.text, _selectedImage);
                    Navigator.of(context)
                        .pushReplacement(MaterialPageRoute(builder: (context) => InterestsScreen(isEditing: false)));
                  } else {
                    await _updateProfile();
                    widget.onUpdateProfile!.call();
                    if (context.mounted) Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.isNew
                  ? [
                      TextButton(
                        onPressed: () async {
                          await _createProfile(_userName.text, null);
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => InterestsScreen(isEditing: false)));
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [Text("Skip"), Icon(Icons.arrow_forward_rounded)],
                        ),
                      ),
                    ]
                  : [],
            ),
          ],
        ),
      ),
    );
  }
}

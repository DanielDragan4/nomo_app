import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/user_signup_provider.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:uuid/uuid.dart';

class CreateAccountScreen extends ConsumerStatefulWidget {
  CreateAccountScreen(
      {super.key,
      required this.isNew,
      this.avatar,
      this.profilename,
      this.username});

  bool isNew;
  String? avatar;
  String? username;
  String? profilename;

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

  Future _pickImageFromGallery() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  Future _pickImageFromCamera() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.camera);

    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  dynamic uploadAvatar(File? imageFile) async {
    final supabase = (await ref.watch(supabaseInstance));
    final userId = supabase.client.auth.currentUser!.id.toString();
    var imgId;

    var uuid = const Uuid();
    final currentImageName = uuid.v4();

    if (imageFile != null) {
      final response = await supabase.client.storage
          .from('Images')
          .upload('$userId/avatar/$currentImageName', imageFile);

      imgId = await supabase.client
          .from('Images')
          .insert({'image_url': '$userId/avatar/$currentImageName'}).select(
              'images_id');
    } else {
      imgId = await supabase.client.from('Images').insert(
          {'image_url': 'default/avatar/sadboi.png'}).select('images_id');
    }
    return imgId[0]["images_id"];
  }

  Future _createProfile(String user, File? _selectedImage) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    var avatarId = await uploadAvatar(_selectedImage);

    if (user.replaceAll(' ', '') == '') {
      user =
          'User-${supabase.auth.currentUser!.id.replaceAll('-', '').substring(0, 10)}';
    }

    final newProfileRowMap = {
      'profile_id': supabase.auth.currentUser!.id,
      'avatar_id': avatarId,
      'username': user,
      'profile_name': _profileName.text
    };

    if (_profileName.text.replaceAll(' ', '') != '') {
      newProfileRowMap['profile_name'] = _profileName.text;
    }
    if (widget.isNew) {
      await supabase.from('Profiles').insert(newProfileRowMap);
    } else {
      await supabase.from('Profiles').update(
        {
          'avatar_id': avatarId,
          'username': user,
          'profile_name': _profileName.text
        },
      ).eq('profile_id', newProfileRowMap['profile_id']);
    }
  }

  //TODO: delete previous avatar to save space
  Future _updateProfile() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    var avatarId = _selectedImage != null
        ? await uploadAvatar(_selectedImage)
        : await supabase
            .from('Profile')
            .select('avatar_id')
            .eq('profile_id', supabase.auth.currentUser!.id);
    var user = _userName.text;
    final userId = (await ref.watch(supabaseInstance))
        .client
        .auth
        .currentUser!
        .id
        .toString();

    if (_selectedImage != null) {
      await supabase.storage.from('Images').remove(['$userId/avatar/$avatar']);
    }

    if (user.replaceAll(' ', '') == '') {
      user =
          'User-${supabase.auth.currentUser!.id.replaceAll('-', '').substring(0, 10)}';
    }
    final updateProfileRowMap = {
      'avatar_id': avatarId,
      'username': user,
      'profile_name': _profileName.text
    };

    await supabase
        .from('Profiles')
        .update(updateProfileRowMap)
        .eq('profile_id', supabase.auth.currentUser!.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 12.0),
              child: Text(
                "Create Account",
                style: TextStyle(fontSize: 20),
              ),
            ),
            //const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                child: Text("Select from Gallery"),
                                onPressed: () {
                                  _pickImageFromGallery();
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text("Take a Picture"),
                                onPressed: () {
                                  _pickImageFromCamera();
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: Text("Close"),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ]),
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
                        : (avatar != null
                            ? NetworkImage(avatar!) as ImageProvider
                            : null),
                    child: _selectedImage == null && avatar == null
                        ? Container(
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color.fromARGB(255, 63, 53, 78),
                                      Color.fromARGB(255, 112, 9, 167),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius:
                                    BorderRadius.circular(radius - 2)),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 20,
                controller: _profileName,
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
                maxLength: 20,
                controller: _userName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Username",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            //const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 11,
                controller: _phoneNum,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Phone Number",
                  contentPadding: EdgeInsets.all(5),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            //SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: ElevatedButton(
                child: widget.isNew ? Text("Create Account") : Text("Update"),
                onPressed: () async {
                  await _createProfile(_userName.text, _selectedImage);
                  ref.watch(onSignUp.notifier).completeProfileCreation();
                  ref
                      .watch(savedSessionProvider.notifier)
                      .changeSessionDataList();
                  Navigator.of(context).pop();
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
                          ref
                              .watch(onSignUp.notifier)
                              .completeProfileCreation();
                          ref
                              .watch(savedSessionProvider.notifier)
                              .changeSessionDataList();
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Skip"),
                            Icon(Icons.arrow_forward_rounded)
                          ],
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

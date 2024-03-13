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
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() {
    return _CreateAccountScreenState();
  }
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  File? _selectedImage;
  double radius = 75;
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _userName = TextEditingController();
  final _phoneNum = TextEditingController();

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

  dynamic uploadAvatar(File imageFile) async {
    final supabase = (await ref.watch(supabaseInstance));
    final userId = supabase.client.auth.currentUser!.id.toString();

    var uuid = const Uuid();
    final currentImageName = uuid.v4();

    final response = await supabase.client.storage
        .from('Images')
        .upload('$userId/avatar/$currentImageName', imageFile);

    var imgId = await supabase.client.from('Images').insert(
        {'image_url': '$userId/avatar/$currentImageName'}).select('images_id');

    return imgId[0]["images_id"];

    // if (response.error == null) {
    //   print('Image uploaded successfully');
    // } else {
    //   print('Upload error: ${response.error!.message}');
    // }
  }

  Future _createProfile(String user) async {
    var avatarId = await uploadAvatar(_selectedImage!);
    final supabase = (await ref.read(supabaseInstance)).client;

    if (user.replaceAll(' ', '') == '') {
      user = 'User-${supabase.auth.currentUser!.id.replaceAll('-', '').substring(0, 10)}';
    }

    final newProfileRowMap = {
      'profile_id': supabase.auth.currentUser!.id,
      'avatar_id': avatarId,
      'username': user,
    };

    await supabase.from('Profiles').insert(newProfileRowMap);
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
                        : null,
                    child: _selectedImage == null
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
                controller: _firstName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "First Name",
                  contentPadding: EdgeInsets.all(5),
                ),
              ),
            ),
            //const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(7.0),
              child: TextField(
                maxLength: 20,
                controller: _lastName,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Last Name",
                  contentPadding: EdgeInsets.all(5),
                ),
                keyboardType: TextInputType.phone,
              ),
            ),
            //const SizedBox(height: 10),
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
                child: const Text("Create Account"),
                onPressed: () {
                  _createProfile(_userName.text);
                  ref.watch(onSignUp.notifier).completeProfileCreation();
                  ref.watch(savedSessionProvider.notifier).changeSessionDataList();
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    //ToDO: Set default image and username (same as no username input)
                  ref.watch(onSignUp.notifier).completeProfileCreation();
                  ref.watch(savedSessionProvider.notifier).changeSessionDataList();
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text("Skip"), Icon(Icons.arrow_forward_rounded)],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Future<List<Friend>> _friendsFuture;
  bool _isLoading = false;
  List<Friend> _friends = [];
  List<String> members = [];
  bool createGroup = false;
  double radius = 75;
  String? avatar;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _getFriends();
    _scrollController.addListener(_onScrolled);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Friend>> _getFriends() async {
    final friends = await ref.read(profileProvider.notifier).decodeFriends();
    return friends;
  }

  void _onScrolled() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _loadMoreFriends();
    }
  }

  Future<void> _loadMoreFriends() async {
    setState(() {
      _isLoading = true;
    });

    final newFriends = await _getFriends();
    setState(() {
      _friends.addAll(newFriends);
      _isLoading = false;
    });
  }

  void _addToGroup(bool removeAdd, String userId) {
    /*
      Adds a user to a group chat based on their userId based on wether they should be removed or added

      Params: bool removeAdd, String userId
      
      Returns: none
    */
    setState(() {
      if (removeAdd) {
        if (!members.contains(userId)) {
          members.add(userId);
          // If the user is not already in _friends, add them
          if (!_friends.any((friend) => friend.friendProfileId == userId)) {
            _getFriendById(userId).then((friend) {
              if (friend != null) {
                setState(() {
                  _friends.add(friend);
                });
              }
            });
          }
        }
      } else {
        members.remove(userId);
      }
    });
  }

  Future<Friend?> _getFriendById(String userId) async {
    // Implement this method to fetch a friend by their ID
    // You might need to add this method to your profile provider
    return await ref.read(profileProvider.notifier).getFriendById(userId);
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

  dynamic uploadGroupAvatar(File? imageFile) async {
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
            await supabase.client.storage.from('Images').upload('$userId/groups/$currentImageName', tempFile);

        // Delete the temporary file
        await tempFile.delete();

        imgId = await supabase.client
            .from('Images')
            .insert({'image_url': '$userId/groups/$currentImageName'}).select('images_id');
      } else {
        // Handle error: unable to decode image
        throw Exception('Unable to decode image');
      }
    } else {
      imgId = await supabase.client
          .from('Images')
          .insert({'image_url': 'default/avatar/nomo_logo_2.jpg'}).select('images_id');
    }
    return imgId[0]["images_id"];
  }

  @override
  Widget build(BuildContext context) {
    if (titleController.text.isNotEmpty && members.isNotEmpty) {
      createGroup = true;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * .1,
        title: const Text('New Group'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            TextField(
              autofocus: false,
              controller: titleController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(MediaQuery.of(context).size.height * .005),
                border: const UnderlineInputBorder(borderSide: BorderSide()),
                hintText: 'Add a title',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                focusColor: Theme.of(context).colorScheme.onSecondary,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: FutureBuilder<List<Friend>>(
                      future: _friendsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        } else {
                          _friends = snapshot.data ?? [];
                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: _friends.length + (_isLoading ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index < _friends.length) {
                                return FriendTab(
                                  friendData: _friends[index],
                                  isRequest: true,
                                  groupMemberToggle: _addToGroup,
                                  toggle: true,
                                  isEventAttendee: false,
                                );
                              } else {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                            },
                          );
                        }
                      },
                    ),
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchScreen(
                              searchingPeople: true,
                              addToGroup: _addToGroup,
                            ),
                          ),
                        );
                      },
                      child: Text('Add others')),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: createGroup
                  ? () async {
                      String? avatarPath = await uploadGroupAvatar(_selectedImage);
                      ref.read(chatsProvider.notifier).createNewGroup(
                            titleController.text,
                            members,
                            avatarPath,
                          );
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName('/'),
                      );
                    }
                  : null,
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}

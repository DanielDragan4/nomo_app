import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
//import 'package:nomo/models/comments_model.dart';

class CommentWidget extends ConsumerWidget {
  const CommentWidget({super.key, required this.commentData});

  final Comment commentData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: .5,
          ),
        ),
      width: double.infinity,
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width / 150),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder(
                      future: ref.read(supabaseInstance),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return CircleAvatar(
                            radius: MediaQuery.sizeOf(context).width / 25,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(
                              commentData.profileUrl,
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error loading image: ${snapshot.error}');
                        } else if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                   ),
                    SizedBox(width: MediaQuery.sizeOf(context).height / 150),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                commentData.username,//widget.eventData.hostUsername,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: MediaQuery.of(context).size.width * .03),
                              ),
                              SizedBox(width: MediaQuery.sizeOf(context).height / 150),
                              Text(
                                Jiffy.parseFromDateTime(DateTime.parse(commentData.timeStamp)).fromNow() ,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.w300,
                                  fontSize: MediaQuery.of(context).size.width * .025),
                          ),
                            ],
                          ),
                           Text(
                              commentData.comment_text,
                              softWrap: true,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: MediaQuery.of(context).size.width * .03
                                  ),
                            ),
                        ],
                      ),
                    )
                ],
              )
            ],
          ),
        ),
    );
  }
}
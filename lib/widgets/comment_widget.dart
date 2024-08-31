// comment_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';

// Builds a widget for each individual comment in the Comments Section list, including sender avatar and name
//
// Parameters:
// - 'commentData': Data for the specific comment being diplayed (includes comment + sender data)

class CommentWidget extends ConsumerWidget {
  const CommentWidget({
    super.key,
    required this.commentData,
  });

  final Comment commentData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 2,
      margin: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.005,
        horizontal: MediaQuery.of(context).size.width * 0.02,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width * 0.015,
            MediaQuery.of(context).size.width * 0.03,
            MediaQuery.of(context).size.width * 0.015,
            MediaQuery.of(context).size.width * 0.03),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder(
              future: ref.read(supabaseInstance),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return CircleAvatar(
                    radius: MediaQuery.of(context).size.width * 0.0435,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: NetworkImage(commentData.profileUrl),
                  );
                } else if (snapshot.hasError) {
                  return Icon(Icons.error, color: Colors.red);
                } else {
                  return CircularProgressIndicator();
                }
              },
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          commentData.username,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width * 0.0435,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                      Icon(
                        Icons.circle,
                        size: MediaQuery.of(context).size.width * 0.012,
                        color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.6),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.015),
                      Text(
                        Jiffy.parseFromDateTime(DateTime.parse(commentData.timeStamp)).fromNow(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.6),
                          fontSize: MediaQuery.of(context).size.width * 0.0325,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Text(
                    commentData.comment_text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: MediaQuery.of(context).size.width * 0.0425,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

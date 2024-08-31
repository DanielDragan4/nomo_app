import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/widgets/comment_widget.dart';

// Bottom sheet used to display event comments section outside of detailed event view
//
// Parameters:
// - 'eventId': ID of event for which to retreive list of comments

class CommentsSection extends ConsumerStatefulWidget {
   const CommentsSection({super.key, required this.eventId, required this.onIncrementCounter});

  final eventId;
  final VoidCallback onIncrementCounter;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final newComment = TextEditingController();
  List<Comment> commentsList = [];

  @override
  void initState() {
    super.initState();
    receiveComments();
  }

  Future<void> receiveComments() async {
    var readComments = await ref.read(eventsProvider.notifier).getComments(widget.eventId);
    setState(() {
      commentsList = readComments;
    });
  }

  Future<void> postComment(String comment) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    commentsList = await ref
        .read(eventsProvider.notifier)
        .postComment(supabase.auth.currentUser!.id, widget.eventId, comment, null);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: commentsList.isNotEmpty
                ? ListView.builder(
                    itemCount: commentsList.length,
                    itemBuilder: (context, index) => CommentWidget(commentData: commentsList[index]),
                  )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.height * 0.001),
                      child: Text(
                        "No comments available",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.6),
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.w100 
                        ),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.02,
              MediaQuery.of(context).size.width * 0.02,
              MediaQuery.of(context).size.width * 0.02,
              MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // Light grey color
                borderRadius: BorderRadius.circular(8), // Rounded corners
              ),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: newComment,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.6), fontSize: MediaQuery.of(context).size.height * .02),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: MediaQuery.of(context).size.width * 0.04,
                          vertical: MediaQuery.of(context).size.height * 0.015,
                        ),
                      ),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width * 0.02),
                  IconButton(
                    onPressed: () {
                      if (newComment.text.isNotEmpty) {
                        postComment(newComment.text);
                        newComment.clear();
                        receiveComments();
                        widget.onIncrementCounter();
                      }
                    },
                    icon: Icon(Icons.send),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

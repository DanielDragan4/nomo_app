import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/comment_widget.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({super.key, required this.eventId});

  final eventId;

  @override
  ConsumerState<CommentsSection> createState() {
    return _CommentsSectionState();
  }
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
   final newComment = TextEditingController();
   List<Comment> commentsList = [];

  @override
  void initState() {
    super.initState();
    recieveComments();
  }

  Future<void> recieveComments() async{
       var readComments = await ref.read(eventsProvider.notifier).getComments(widget.eventId);
      setState(() {
        commentsList = readComments;
      });
    }

   Future<void> postComment(String comment) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    commentsList = await ref.read(eventsProvider.notifier)
    .postComment(supabase.auth.currentUser!.id, widget.eventId, comment, null);
  }

  @override
  Widget build(BuildContext context) {

    final bool activeComments;
    bool inputComment = false;
    
    if(commentsList != null && commentsList.isNotEmpty) {
      activeComments = true;
    }else {
      activeComments = false;
    }

    if(newComment.text.isNotEmpty) {
      setState(() {
        inputComment = true;        
      });
    }

    return Container(
      child: 
      Column(
        children: [
      (activeComments ?
        SizedBox(
          height: MediaQuery.of(context).size.height *.3,
          child: ListView(
            children: [
              for (Comment i in commentsList) 
                CommentWidget(commentData: i)
            ],
          ),
        )
        :  
        Text("No Comments Avalible", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))),
        Row(
          children: [
              TextField(
                autofocus: false,
                controller: newComment,
                  decoration: InputDecoration(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height *.033, maxWidth:  MediaQuery.of(context).size.width *.86),
                    contentPadding: EdgeInsets.all(MediaQuery.of(context).size.height *.005),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                    ),
                    hintText: 'Add a Comment',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    focusColor:Theme.of(context).colorScheme.onSecondary
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                ),
              inputComment ?
                IconButton(onPressed: () {
                  postComment(newComment.text);
                  setState(() {
                    newComment.clear();
                    recieveComments();
                  });
                  
                }, icon: Icon(Icons.send_rounded),color: Theme.of(context).colorScheme.onSecondary)
                :
                SizedBox(
                  width: MediaQuery.of(context).size.width * .1,
                )
          ],
        ),
        ]
      )         
    );
  }
}
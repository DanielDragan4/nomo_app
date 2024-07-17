import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/profile_screen.dart';
import 'package:nomo/widgets/comments_section_widget.dart';
import 'package:nomo/widgets/event_info.dart';

class DetailedEventScreen extends ConsumerStatefulWidget {
  DetailedEventScreen({
    Key? key,
    this.eventData,
    this.linkEventId,
  }) : super(key: key);

  Event? eventData;
  final String? linkEventId;

  @override
  ConsumerState<DetailedEventScreen> createState() => _DetailedEventScreenState();
}

class _DetailedEventScreenState extends ConsumerState<DetailedEventScreen> {
  Event? event;

  Future<void> _initializeEventData() async {
    /*
     gets all event data from an active link based on the eventID from the share link, this then sets
     the event for the Event Screen

      Params: none
      
      Returns: none
    */
    if (widget.linkEventId != null) {
      event = await ref.read(eventsProvider.notifier).deCodeLinkEvent(widget.linkEventId!);
    } else {
      event = widget.eventData!;
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _initializeEventData();
  }

  @override
  Widget build(BuildContext context) {
    if (event == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          event!.title,
          style: TextStyle(color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventImage(),
              const SizedBox(height: 16),
              _buildEventHost(),
              const SizedBox(height: 16),
              EventInfo(eventsData: event!),
              const SizedBox(height: 16),
              _buildEventDescription(),
              const SizedBox(height: 24),
              _buildCommentsSection(),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          event!.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.error),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventHost() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileScreen(isUser: false, userId: widget.eventData?.host),
        )),
          child: Row (children: 
          [
            CircleAvatar(
            radius: MediaQuery.of(context).devicePixelRatio *7,
            backgroundImage: NetworkImage(event!.hostProfileUrl),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hosted by',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                event!.hostUsername,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),]),
        )
      ],
    );
  }

  Widget _buildEventDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          event!.description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comments',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        CommentsSection(eventId: event!.eventId),
      ],  
    );
  }
}
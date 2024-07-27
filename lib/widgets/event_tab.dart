import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:nomo/screens/profile_screen.dart';
import 'package:nomo/widgets/event_info.dart';

// Widget used to display all event information in recommended and profile screen
// Calls EventInfo to build all details below the location
//
// Parameters:
// - 'eventData': all relevant data pertaining to specific event
// - 'bookmarkSet(optional)': if current user has this event bookmarked or not
// - 'preloadedImage'(optional): image for specified event. only passed in if already loaded

class EventTab extends ConsumerStatefulWidget {
  EventTab({Key? key, required this.eventData, this.bookmarkSet, this.preloadedImage}) : super(key: key);

  final Event eventData;
  final bool? bookmarkSet;
  final ImageProvider? preloadedImage;

  @override
  ConsumerState<EventTab> createState() => _EventTabState();
}

class _EventTabState extends ConsumerState<EventTab> {
  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.parse(widget.eventData.sdate);
    final formattedDate = "${date.month}/${date.day}/${date.year} at ${_getFormattedHour(date)}";

    final bool isHostOrAttending = widget.eventData.isHost || widget.eventData.attending;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: isHostOrAttending
          ? Theme.of(context).colorScheme.primaryContainer // Color for hosted/attended events
          : Theme.of(context).cardColor, // Default card color
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHostInfo(context),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: Container(
                      child: Row(children: [
                        if (_hasEventEnded()) _buildEventEndedIndicator(),
                        SizedBox(width: 4,),
                        if (isHostOrAttending) _buildHostOrAttendingIndicator(),
                      ],),
                    ),
                  )

                ],
              ),
              _buildEventImage(context),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEventTitle(context),
                    const SizedBox(height: 8),
                    _buildEventLocation(context),
                    EventInfo(
                      eventsData: widget.eventData,
                      bookmarkSet: widget.bookmarkSet,
                    ),
                    const SizedBox(height: 12),
                    //_buildEventDescription(context),
                    const SizedBox(height: 12),
                    _buildGetDetails(context)
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHostOrAttendingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: widget.eventData.isHost ? Colors.green : Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.eventData.isHost ? 'Hosting' : 'Attending',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  bool _hasEventEnded() {
    final DateTime endDate = DateTime.parse(widget.eventData.edate);
    return DateTime.now().isAfter(endDate);
  }

  Widget _buildEventEndedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Passed',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildHostInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).devicePixelRatio * 2.5),
      child: GestureDetector(
        onTap: () async {
          String currentUser = await ref.read(profileProvider.notifier).getCurrentUserId();
          if (widget.eventData.host != currentUser) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(isUser: false, userId: widget.eventData.host),
              ),
            );
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileScreen(isUser: true, userId: widget.eventData.host),
              ),
            );
          }
          //Refresh data when popping back to your profile
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.findAncestorStateOfType<ProfileScreenState>()?.refreshData();
            });
          }
        },
        child: Row(
          children: [
            _buildHostAvatar(context),
             SizedBox(width: MediaQuery.of(context).size.height * .012),
            Text(
              '@${widget.eventData.hostUsername}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostAvatar(BuildContext context) {
    return FutureBuilder(
      future: ref.read(supabaseInstance),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return CircleAvatar(
            radius: MediaQuery.of(context).devicePixelRatio * 7,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(widget.eventData.hostProfileUrl),
          );
        } else {
          return CircleAvatar(
            radius: MediaQuery.of(context).devicePixelRatio * 7,
            backgroundColor: Colors.grey,
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildEventImage(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DetailedEventScreen(eventData: widget.eventData),
      )),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: widget.preloadedImage != null
            ? Image(image: widget.preloadedImage!, fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: widget.eventData.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Icon(Icons.error),
              ),
      ),
    );
  }

  Widget _buildEventTitle(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DetailedEventScreen(eventData: widget.eventData),
      )),child: 
      Text(
      widget.eventData.title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    ));
  }

  Widget _buildEventLocation(BuildContext context) {
    return (widget.eventData.isVirtual)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.computer, size: 18, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Virtual',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          )
        : GestureDetector(
            onTap: () => MapsLauncher.launchQuery(widget.eventData.location),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 18, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.eventData.location,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildEventDescription(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DetailedEventScreen(eventData: widget.eventData),
      )),
      child: Text(
        widget.eventData.description,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }

  Widget _buildGetDetails(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DetailedEventScreen(eventData: widget.eventData),
          )),child: 
          Text(
          'View Details',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        )),
      ],
    );
  }

  String _getFormattedHour(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'P.M.' : 'A.M.';
    return '$hour $period';
  }
}

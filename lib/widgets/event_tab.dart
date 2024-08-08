import 'package:cached_network_image/cached_network_image.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:nomo/screens/events/new_event_screen.dart';
import 'package:nomo/screens/profile/profile_screen.dart';
import 'package:nomo/widgets/comments_section_widget.dart';
import 'package:nomo/widgets/event_attendees_widget.dart';
import 'package:share_plus/share_plus.dart';

// Widget used to display all event information in recommended and profile screen
// Calls EventInfo to build all details below the location
//
// Parameters:
// - 'eventData': all relevant data pertaining to specific event
// - 'bookmarkSet(optional)': if current user has this event bookmarked or not
// - 'preloadedImage'(optional): image for specified event. only passed in if already loaded
enum Options { itemOne }

class EventTab extends ConsumerStatefulWidget {
  EventTab({Key? key, required this.eventData, this.bookmarkSet, this.preloadedImage}) : super(key: key);

  Event eventData;
  final bool? bookmarkSet;
  final ImageProvider? preloadedImage;

  @override
  ConsumerState<EventTab> createState() => _EventTabState();
}

class _EventTabState extends ConsumerState<EventTab> {
  late bool bookmarkBool;

  @override
  void initState() {
    super.initState();
    bookmarkBool = widget.eventData.bookmarked;
  }

  @override
  void didUpdateWidget(EventTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventData != oldWidget.eventData) {
      setState(() {
        widget.eventData = widget.eventData;
        bookmarkBool = widget.eventData.bookmarked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.parse(widget.eventData.sdate);
    final formattedDate = "${date.month}/${date.day}/${date.year} at ${_getFormattedHour(date)}";

    final bool isHostOrAttending = widget.eventData.isHost || widget.eventData.attending;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: isHostOrAttending ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
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
                    child: Row(
                      children: [
                        if (_hasEventEnded()) _buildEventEndedIndicator(),
                        const SizedBox(width: 4),
                        if (isHostOrAttending) _buildHostOrAttendingIndicator(),
                      ],
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
                    ((widget.eventData.distanceAway != null) || (widget.eventData.isRecurring))
                        ? Row(
                            children: [
                              if (widget.eventData.distanceAway != null) _buildDistanceInfo(context), // Add this line
                              SizedBox(width: 4),
                              if (widget.eventData.isRecurring) _buildRecurringIndicator(),
                            ],
                          )
                        : SizedBox(),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 600;
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateTimeInfo(context, isSmallScreen),
                              const SizedBox(height: 8),
                              _buildAttendeeInfo(context, isSmallScreen),
                              const SizedBox(height: 16),
                              _buildActionButtons(context, isSmallScreen),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildGetDetails(context, isHostOrAttending),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.repeat,
            size: 16,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 4),
          Text(
            'Recurring Event',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getOriginalProfileInfo() async {
    if (Navigator.canPop(context)) {
      await ref.read(attendEventsProvider.notifier).deCodeData();
    }
  }

  Widget _buildDistanceInfo(BuildContext context) {
    if (widget.eventData.distanceAway == null) {
      return const SizedBox.shrink();
    }

    final distance = widget.eventData.distanceAway!;
    final String distanceText = '${distance.toStringAsFixed(1)} miles away';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: GestureDetector(
        onTap: () => MapsLauncher.launchQuery(widget.eventData.location),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_run, // Changed icon to a running person
              size: 18,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(width: 6),
            Text(
              distanceText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostOrAttendingIndicator() {
    var host = widget.eventData.isHost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: host
            ? Theme.of(context).colorScheme.tertiary.withOpacity(0.2)
            : Theme.of(context).colorScheme.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: host ? Colors.green : Color.fromARGB(255, 60, 132, 255),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            host ? Icons.star : Icons.check_circle,
            size: 14,
            color: host ? Colors.green : Color.fromARGB(255, 60, 132, 255),
          ),
          const SizedBox(width: 4),
          Text(
            host ? 'Hosting' : 'Attending',
            style: TextStyle(
              color: host ? Colors.green : Color.fromARGB(255, 60, 132, 255),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasEventEnded() {
    final DateTime endDate = DateTime.parse(widget.eventData.edate);
    return DateTime.now().isAfter(endDate);
  }

  Widget _buildEventEndedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy,
            size: 14,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            'Passed',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
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
            await Navigator.of(context, rootNavigator: true)
                .push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(isUser: false, userId: widget.eventData.host),
                  ),
                )
                .whenComplete(getOriginalProfileInfo);
          } else {
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => ProfileScreen(isUser: true, userId: widget.eventData.host),
              ),
            );
          }
          //Refresh data when popping back to your profile
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              //context.findAncestorStateOfType<ProfileScreenState>()?.refreshData();
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
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
            builder: (context) => DetailedEventScreen(eventData: widget.eventData),
          ))
          .whenComplete(newData),
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
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => DetailedEventScreen(eventData: widget.eventData),
            ))
            .whenComplete(newData),
        child: Text(
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

  Widget _buildGetDetails(BuildContext context, isHostOrAttending) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => DetailedEventScreen(eventData: widget.eventData),
                ))
                .whenComplete(newData),
            child: Text(
              'View Details',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHostOrAttending
                        ? Theme.of(context).colorScheme.onPrimaryContainer // Color for hosted/attended events
                        : Theme.of(context).colorScheme.onSecondary, // Default card color
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

  Widget _buildDateTimeInfo(BuildContext context, bool isSmallScreen) {
    final startDate = DateTime.parse(widget.eventData.sdate);
    final endDate = DateTime.parse(widget.eventData.edate);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    var displayedDates;

    if (dateFormat.format(startDate) == dateFormat.format(endDate)) {
      displayedDates = "${dateFormat.format(startDate)}";
    } else {
      displayedDates = "${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date: $displayedDates',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Time: ${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeeInfo(BuildContext context, bool isSmallScreen) {
    var numAttendees = widget.eventData.attendees.length;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                builder: (context) {
                  return Container(
                    height: MediaQuery.of(context).size.height * .7,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'People Attending',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: AttendeesSection(
                            eventId: widget.eventData.eventId,
                            areFriends: false,
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: _buildInfoItem(context, '$numAttendees', 'Attending', isSmallScreen),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * .04),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
                isScrollControlled: true,
                isDismissible: true,
                context: context,
                builder: (context) {
                  return Container(
                    height: MediaQuery.of(context).size.height * .7,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Friends Attending',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: AttendeesSection(
                            eventId: widget.eventData.eventId,
                            areFriends: true,
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: _buildInfoItem(context, '${widget.eventData.friends.length}', 'Friends', isSmallScreen),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * .04),
        GestureDetector(
          onTap: () {
            if (!Navigator.of(context).canPop()) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                isDismissible: true,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    minChildSize: 0.2,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            SliverToBoxAdapter(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Text(
                                    //   'Comments',
                                    //   style: TextStyle(
                                    //     color: Theme.of(context).primaryColor,
                                    //     fontWeight: FontWeight.bold,
                                    //     fontSize: 30,
                                    //   ),
                                    // ),
                                    // IconButton(
                                    //   icon: const Icon(Icons.close),
                                    //   onPressed: () => Navigator.of(context).pop(),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                            SliverFillRemaining(
                              hasScrollBody: true,
                              child: CommentsSection(eventId: widget.eventData.eventId),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            }
          },
          child: _buildInfoItem(context, '${widget.eventData.numOfComments}', 'Comments', isSmallScreen),
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String value, String label, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _buildJoinLeaveButton(context, isSmallScreen),
        ),
        const SizedBox(width: 8),
        _buildBookmarkButton(context),
        _buildMoreOptionsButton(context),
      ],
    );
  }

  Widget _buildJoinLeaveButton(BuildContext context, bool isSmallScreen) {
    return FutureBuilder(
      future: ref.read(supabaseInstance),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final supabase = snapshot.data!.client;
          final currentUser = supabase.auth.currentUser!.id;
          final isHost = (widget.eventData.host == currentUser);
          bool isAttending = widget.eventData.attending;

          String buttonText = isHost ? 'Edit' : (isAttending ? 'Leave' : 'Join');

          return ElevatedButton(
            onPressed: () => _handleJoinLeaveAction(context, isHost, isAttending, currentUser),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
            ),
            child: Text(buttonText,
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16, color: Theme.of(context).colorScheme.onSecondary)),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _handleJoinLeaveAction(BuildContext context, bool isHost, bool isAttending, String currentUser) {
    if (isHost) {
      _showEditEventDialog(context);
    } else if (isAttending) {
      _showLeaveEventDialog(context);
    } else {
      _joinEvent(context, currentUser);
    }
  }

  void _showEditEventDialog(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: ((context) => NewEventScreen(
            event: widget.eventData,
            isEdit: true,
          )),
    ));
  }

  void _showLeaveEventDialog(BuildContext context) async {
    await attendeeLeaveEvent();
    await ref.read(profileProvider.notifier).deleteBlockedTime(null, widget.eventData.eventId);
    var newEData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(widget.eventData.eventId);

    if (widget.eventData.otherHost != null) {
      newEData.otherAttend = widget.eventData.attending;
      newEData.otherHost = widget.eventData.otherHost;
      newEData.otherBookmark = widget.eventData.otherBookmark;
    }
    setState(() {
      widget.eventData.attending = false;
      widget.eventData.attendees.removeLast();
    });
    newData;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Left ${widget.eventData.title}")),
    );
  }

  Future<void> newData() async {
    Event newEventData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(widget.eventData.eventId);
    if (widget.eventData.otherHost != null) {
      newEventData.otherAttend = widget.eventData.attending;
      newEventData.otherHost = widget.eventData.otherHost;
      newEventData.otherBookmark = widget.eventData.otherBookmark;
    }
    setState(() {
      widget.eventData = newEventData;
    });
  }

  void _joinEvent(BuildContext context, String currentUser) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(profileProvider.notifier).createBlockedTime(
          currentUser,
          widget.eventData.sdate,
          widget.eventData.edate,
          widget.eventData.title,
          widget.eventData.eventId,
        );
    await attendeeJoinEvent();
    var newEventData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(widget.eventData.eventId);
    if (widget.eventData.otherHost != null) {
      newEventData.otherAttend = widget.eventData.attending;
      newEventData.otherHost = widget.eventData.otherHost;
      newEventData.otherBookmark = widget.eventData.otherBookmark;
    }

    setState(() {
      widget.eventData.attending = true;
      widget.eventData.attendees.add(supabase.auth.currentUser!.id);
    });

    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => DetailedEventScreen(
            eventData: widget.eventData,
          ),
        ))
        .whenComplete(newData);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Joined ${widget.eventData.title}")),
    );
  }

  Widget _buildBookmarkButton(BuildContext context) {
    return FutureBuilder(
        future: ref.read(supabaseInstance),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final supabase = snapshot.data!.client;
            final currentUser = supabase.auth.currentUser!.id;
            final isHost = widget.eventData.host == currentUser;
            return (isHost)
                ? const SizedBox()
                : IconButton(
                    onPressed: () {
                      setState(() {
                        bookmarkBool
                            ? {
                                deBookmarkEvent(),
                                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("UnBookmarked ${widget.eventData.title}")),
                                )
                              }
                            : {
                                bookmarkEvent(),
                                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Bookmarked ${widget.eventData.title}")),
                                )
                              };
                        bookmarkBool = !bookmarkBool;
                      });
                    },
                    icon: Icon(
                      bookmarkBool ? Icons.bookmark : Icons.bookmark_border_outlined,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  );
          }
          return const SizedBox();
        });
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return PopupMenuButton<Options>(
      iconColor: Theme.of(context).colorScheme.onSecondary,
      onSelected: (Options item) {
        if (item == Options.itemOne) {
          _shareEventLink();
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<Options>>[
        const PopupMenuItem(value: Options.itemOne, child: Text("Share Link")),
      ],
    );
  }

  Future<void> attendeeJoinEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(eventsProvider.notifier).joinEvent(supabase.auth.currentUser!.id, widget.eventData.eventId);
  }

  Future<void> attendeeLeaveEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(attendEventsProvider.notifier).leaveEvent(widget.eventData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> bookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(eventsProvider.notifier).bookmark(widget.eventData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> deBookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(eventsProvider.notifier).unBookmark(widget.eventData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> _shareEventLink() async {
    final link = await generateBranchLink();
    if (link != null) {
      Share.share(
        'Check out this | ${widget.eventData.title}: $link',
        subject: '${widget.eventData.title}',
      );
    } else {
      print('Error: Unable to generate Branch link');
    }
  }

  Future<String?> generateBranchLink() async {
    BranchUniversalObject buo = BranchUniversalObject(
      canonicalIdentifier: 'event/${widget.eventData.eventId}',
      title: widget.eventData.title,
      imageUrl: widget.eventData.imageUrl,
      contentDescription: widget.eventData.description,
      publiclyIndex: true,
      locallyIndex: true,
      contentMetadata: BranchContentMetaData()..addCustomMetadata("event_id", widget.eventData.eventId),
    );

    BranchLinkProperties lp = BranchLinkProperties(
      channel: 'sharing',
      feature: 'sharing',
      campaign: 'event_share',
      stage: 'user_share',
    )
      ..addControlParam('\$fallback_url', 'https://example.com')
      ..addControlParam('\$ios_url', 'https://apps.apple.com/app/id123456789')
      ..addControlParam('\$android_url', 'https://play.google.com/store/apps/details?id=com.nomo.nomoapp');

    BranchResponse response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
    if (response.success) {
      return response.result;
    } else {
      print('Error generating Branch link: ${response.errorMessage}');
      return null;
    }
  }
}

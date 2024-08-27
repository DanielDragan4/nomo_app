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
import 'package:nomo/widgets/event_date_widget.dart';
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
  bool _isMounted = false;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    bookmarkBool = widget.eventData.bookmarked;
    setState(() {
      _selectedStartDate = DateTime.parse(widget.eventData.attendeeDates['time_start']);
      _selectedEndDate = DateTime.parse(widget.eventData.attendeeDates['time_end']);
    });
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
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
    final bool isHostOrAttending = widget.eventData.isHost || widget.eventData.attending;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Theme.of(context).cardColor,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildHostInfo(context),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMoreOptionsButton(context),
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
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .0075,
                    ),
                    _buildEventLocation(context),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .0075,
                    ),
                    _buildDateTimeInfo(context),
                    ((widget.eventData.distanceAway != null) ||
                            (widget.eventData.isRecurring) ||
                            _hasEventEnded() ||
                            widget.eventData.isHost)
                        ? Row(
                            children: [
                              if (_hasEventEnded()) _buildEventEndedIndicator(),
                              if (_hasEventEnded())
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * .02,
                                ),
                              if (widget.eventData.isHost || widget.eventData.attending)
                                _buildHostOrAttendingIndicator(),
                              if (widget.eventData.isHost || widget.eventData.attending)
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * .02,
                                ),
                              if (widget.eventData.distanceAway != null) _buildDistanceInfo(context), // Add this line
                              if (widget.eventData.distanceAway != null)
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * .02,
                                ),
                              if (widget.eventData.isRecurring) _buildRecurringIndicator(),
                            ],
                          )
                        : SizedBox(),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .015,
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 600;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAttendeeInfo(context, isSmallScreen),
                            const SizedBox(height: 16),
                            _buildActionButtons(context, isSmallScreen, isHostOrAttending),
                          ],
                        );
                      },
                    ),
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
    final String distanceText = '${distance.toStringAsFixed(1)} mi';

    return GestureDetector(
      onTap: () => MapsLauncher.launchQuery(widget.eventData.location),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.navigation_outlined,
              size: MediaQuery.of(context).devicePixelRatio * 5.5,
              weight: .01,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              distanceText,
              style: TextStyle(
                fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSecondary,
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
        color: host ? Colors.green : Color.fromARGB(255, 30, 42, 138),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(host ? 'Hosting' : 'Attending',
              style: host
                  ? TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                    )
                  : TextStyle(
                      color: Color.fromARGB(255, 98, 169, 255),
                      fontWeight: FontWeight.w500,
                      fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                    )),
        ],
      ),
    );
  }

  bool _hasEventEnded() {
    final DateTime endDate = DateTime.parse(widget.eventData.edate.last);
    return DateTime.now().isAfter(endDate);
  }

  Widget _buildEventEndedIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 179, 38, 28),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Passed',
            style: TextStyle(
              color: Color.fromARGB(255, 219, 169, 166),
              fontWeight: FontWeight.w500,
              fontSize: MediaQuery.of(context).devicePixelRatio * 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostInfo(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).devicePixelRatio * 3),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHostAvatar(context),
            SizedBox(width: MediaQuery.of(context).size.width * 0.0275),
            Flexible(
              child: Text(
                widget.eventData.hostUsername,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: MediaQuery.of(context).devicePixelRatio * 5,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
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
            radius: MediaQuery.of(context).devicePixelRatio * 6,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(widget.eventData.hostProfileUrl),
          );
        } else {
          return CircleAvatar(
            radius: MediaQuery.of(context).devicePixelRatio * 6,
            backgroundColor: Colors.grey,
            child: const CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Widget _buildEventImage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
      child: GestureDetector(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => DetailedEventScreen(eventData: widget.eventData),
            ))
            .whenComplete(newData),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: (widget.preloadedImage != null)
                ? Container(
                    decoration: BoxDecoration(color: Colors.black),
                    child: Image(image: widget.preloadedImage!, fit: BoxFit.cover))
                : Container(
                    decoration: BoxDecoration(color: Colors.black),
                    child: CachedNetworkImage(
                      imageUrl: widget.eventData.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
          ),
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
          style: TextStyle(
            fontSize: MediaQuery.of(context).devicePixelRatio * 7,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ));
  }

  Widget _buildEventLocation(BuildContext context) {
    return (widget.eventData.isVirtual)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.computer,
                  size: MediaQuery.of(context).devicePixelRatio * 8.5, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Virtual',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w300,
                          color: Theme.of(context).colorScheme.onSurface,
                        )),
              ),
            ],
          )
        : GestureDetector(
            onTap: () => MapsLauncher.launchQuery(widget.eventData.location),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: MediaQuery.of(context).devicePixelRatio * 7, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.eventData.location,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w300,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                          )),
                ),
              ],
            ),
          );
  }

  Widget _buildDateTimeInfo(BuildContext context) {
    final startDate = _selectedStartDate;
    final endDate = _selectedEndDate;
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    var displayedDates;

    if (dateFormat.format(startDate) == dateFormat.format(endDate)) {
      displayedDates = "${dateFormat.format(startDate)}";
    } else {
      displayedDates = "${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}";
    }

    return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: (dateFormat.format(startDate) == dateFormat.format(endDate))
            ? Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                Container(
                    child: Row(children: [
                  Icon(Icons.calendar_today,
                      size: MediaQuery.of(context).devicePixelRatio * 6,
                      color: Theme.of(context).colorScheme.onSurface),
                  const SizedBox(width: 8),
                  Text(
                    displayedDates,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ])),
                SizedBox(
                  width: MediaQuery.of(context).size.width * .05,
                ),
                Container(
                    child: Row(
                  children: [
                    Icon(Icons.access_time,
                        size: MediaQuery.of(context).devicePixelRatio * 6,
                        color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      '${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).devicePixelRatio * 3.75,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ))
              ])
            : Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Icon(Icons.calendar_today,
                        size: MediaQuery.of(context).devicePixelRatio * 6,
                        color: Theme.of(context).colorScheme.onSurface),
                    const SizedBox(width: 8),
                    Text(
                      displayedDates,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ]),
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: MediaQuery.of(context).devicePixelRatio * 6,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        '${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).devicePixelRatio * 3.75,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  )
                ],
              ));
  }

  Widget _buildGetDetails(BuildContext context, isHostOrAttending) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor, // Background color
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height * .0185, horizontal: MediaQuery.of(context).size.width * 0.23),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
      ),
      onPressed: () {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (context) => DetailedEventScreen(eventData: widget.eventData),
            ))
            .whenComplete(newData);
      },
      child: Text(
        'View details',
        style: TextStyle(
          fontSize: MediaQuery.of(context).devicePixelRatio * 4.25,
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getFormattedHour(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'P.M.' : 'A.M.';
    return '$hour $period';
  }

  Widget _buildAttendeeInfo(BuildContext context, bool isSmallScreen) {
    var numAttendees = widget.eventData.attendees.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        SizedBox(width: MediaQuery.of(context).size.width * .02),
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
        SizedBox(width: MediaQuery.of(context).size.width * .02),
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
                                  children: [],
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.06,
      width: MediaQuery.of(context).size.width * 0.27,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          width: 0.3,
          color: Color.fromARGB(200, 128, 122, 122),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).devicePixelRatio * 4.25,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: MediaQuery.of(context).devicePixelRatio * 4.25,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen, bool isHostOrAttending) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildGetDetails(context, isHostOrAttending),
        _buildBookmarkButton(context),
      ],
    );
  }

  Future<void> newData() async {
    if (!_isMounted) return;

    Event newEventData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(widget.eventData.eventId);
    if (widget.eventData.otherHost != null) {
      newEventData.otherAttend = widget.eventData.attending;
      newEventData.otherHost = widget.eventData.otherHost;
      newEventData.otherBookmark = widget.eventData.otherBookmark;
    }
    if (widget.eventData.distanceAway != null) {
      newEventData.distanceAway = widget.eventData.distanceAway;
    }
    setState(() {
      widget.eventData = newEventData;
    });
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
                : Container(
                    height: MediaQuery.of(context).size.height * .0633,
                    width: MediaQuery.of(context).size.width * .14,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary, // Light grey color
                      borderRadius: BorderRadius.circular(10), // Rounded corners
                    ),
                    child: IconButton(
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
                        size: MediaQuery.of(context).devicePixelRatio * 7.5,
                      ),
                    ),
                  );
          }
          return const SizedBox();
        });
  }

  Widget _buildMoreOptionsButton(BuildContext context) {
    return PopupMenuButton<Options>(
      icon: const Icon(Icons.more_horiz),
      iconColor: Theme.of(context).colorScheme.onSecondary,
      iconSize: MediaQuery.of(context).devicePixelRatio * 8,
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

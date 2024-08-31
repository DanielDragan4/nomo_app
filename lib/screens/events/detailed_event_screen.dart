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
import 'package:nomo/screens/events/new_event_screen.dart';
import 'package:nomo/screens/profile/other_profile_screen.dart';
import 'package:nomo/widgets/comments_section_widget.dart';
import 'package:nomo/widgets/event_attendees_widget.dart';
import 'package:share_plus/share_plus.dart';

enum Options { itemOne }

class DetailedEventScreen extends ConsumerStatefulWidget {
  DetailedEventScreen({Key? key, required this.eventData}) : super(key: key);

  Event eventData;

  @override
  ConsumerState<DetailedEventScreen> createState() => _DetailedEventScreenState();
}

class _DetailedEventScreenState extends ConsumerState<DetailedEventScreen> {
  late bool bookmarkBool;
  DateTime _selectedStartDate = DateTime.now();
  DateTime _selectedEndDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    bookmarkBool = widget.eventData.bookmarked;
    setState(() {
      _selectedStartDate = DateTime.parse(widget.eventData.attendeeDates['time_start']);
      _selectedEndDate = DateTime.parse(widget.eventData.attendeeDates['time_end']);
    });
  }

  @override
  void didUpdateWidget(DetailedEventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.eventData != oldWidget.eventData) {
      setState(() {
        widget.eventData = widget.eventData;
        bookmarkBool = widget.eventData.bookmarked;
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      widget.eventData.numOfComments = (widget.eventData.numOfComments + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                automaticallyImplyLeading: false,
                toolbarHeight: kToolbarHeight + (MediaQuery.of(context).size.height * 0.14),
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: _buildEventImage(),
                // actions: [
                //   IconButton(
                //     icon: Icon(Icons.more_vert, color: Colors.white),
                //     onPressed: () {
                //       // Add your menu logic here
                //     },
                //   ),
                // ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      widget.eventData.title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.height * 0.03),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    _buildEventHost(),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                    _buildEventLocation(context),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.0025),
                    _buildDateTimeInfo(context),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                    if (widget.eventData.distanceAway != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IntrinsicWidth(
                          child: _buildDistanceInfo(context),
                        ),
                      ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    _buildAttendeeInfo(context, false),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    _buildActionButtons(context, false),
                    const SizedBox(height: 16),
                    _buildEventDescription(),
                    const SizedBox(height: 24),
                    _buildCommentsSection(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      _buildBackButton(),
      _buildMoreOptionsButton()
    ]);
  }

  Future<void> getOriginalProfileInfo() async {
    if (Navigator.canPop(context)) {
      await ref.read(attendEventsProvider.notifier).deCodeData();
    }
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height * .03 + MediaQuery.of(context).padding.top,
      left: MediaQuery.of(context).size.width * .033,
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        height: MediaQuery.of(context).size.width * .11,
        width: MediaQuery.of(context).size.width * .11,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary, // Light grey color
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Center(
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * .055,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 24,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreOptionsButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height * .03 + MediaQuery.of(context).padding.top,
      right: MediaQuery.of(context).size.width * .033,
      child: Container(
        height: MediaQuery.of(context).size.width * .11,
        width: MediaQuery.of(context).size.width * .11,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary, // Light grey color
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Center(
          child: PopupMenuButton<Options>(
            icon: Icon(
              Icons.more_horiz,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: MediaQuery.of(context).size.width * .075,
            ),
            onSelected: (Options item) {
              if (item == Options.itemOne) {
                _shareEventLink();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<Options>>[
              PopupMenuItem(
                  value: Options.itemOne,
                  child: Text(
                    "Share Link",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                  )),
            ],
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 24,
            color: Theme.of(context).colorScheme.secondary,
          ),
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
          widget.eventData.imageUrl,
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
          onTap: () {
            Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => OtherProfileScreen(userId: widget.eventData.host),
                ))
                .whenComplete(getOriginalProfileInfo);
          },
          child: Row(children: [
            CircleAvatar(
              radius: MediaQuery.of(context).size.width * 0.0525,
              backgroundImage: NetworkImage(widget.eventData.hostProfileUrl),
            ),
            SizedBox(width: MediaQuery.of(context).size.width * 0.032),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.75, // Adjust this value as needed
                  child: Text(
                    '@${widget.eventData.hostUsername}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: MediaQuery.of(context).size.width * 0.0465,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  'Hosted by',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                  ),
                ),
              ],
            ),
          ]),
        )
      ],
    );
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
              size: MediaQuery.of(context).size.width * .05,
              weight: .01,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              distanceText,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.04,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventLocation(BuildContext context) {
    return (widget.eventData.isVirtual)
        ? Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.computer,
                  size: MediaQuery.of(context).size.width * 0.067, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Virtual',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: MediaQuery.of(context).size.width * .0425)),
              ),
            ],
          )
        : GestureDetector(
            onTap: () => MapsLauncher.launchQuery(widget.eventData.location),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: MediaQuery.of(context).size.width * .067, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.eventData.location,
                      style: TextStyle(
                        fontWeight: FontWeight.w100,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: MediaQuery.of(context).size.width * .0425,
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

    return GestureDetector(
      onTap: () {
        _showDateTimeSelectorDialog(context);
      },
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: (dateFormat.format(startDate) == dateFormat.format(endDate))
              ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Container(
                      child: Row(children: [
                    Icon(
                      Icons.calendar_today,
                      size: MediaQuery.of(context).size.width * .055,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayedDates,
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * .0425,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w100),
                    ),
                  ])),
                  Container(
                      child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: MediaQuery.of(context).size.width * .055,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        '${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * .0425,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w100),
                      ),
                    ],
                  ))
                ])
              : Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                      Icon(Icons.calendar_today,
                          size: MediaQuery.of(context).size.width * .055,
                          color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        displayedDates,
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * .0425,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w100),
                      ),
                    ]),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: MediaQuery.of(context).size.width * .055,
                            color: Theme.of(context).colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text(
                          '${timeFormat.format(startDate)} - ${timeFormat.format(endDate)}',
                          style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * .0425,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w100),
                        ),
                      ],
                    )
                  ],
                )),
    );
  }

  Widget _buildEventDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.width * .0575,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.eventData!.description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: MediaQuery.of(context).size.width * .04,
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
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: MediaQuery.of(context).size.width * .0575,
          ),
        ),
        Container(
          height: (!(widget.eventData.numOfComments == 0))
              ? MediaQuery.of(context).size.height * .6
              : MediaQuery.of(context).size.height * .25,
          child: CommentsSection(
            eventId: widget.eventData!.eventId,
            onIncrementCounter: _incrementCounter,
          ),
        ),
      ],
    );
  }

  void _showDateTimeSelectorDialog(BuildContext context) {
    List<DateTime> parsedStartDates = [];
    List<DateTime> parsedEndDates = [];
    for (var event in widget.eventData.sdate) {
      parsedStartDates.add(DateTime.parse(event));
    }
    for (var event in widget.eventData.edate) {
      parsedEndDates.add(DateTime.parse(event));
    }
    int? _selectedIndex = 0;
    for (var i = 0; i < parsedStartDates.length; i++) {
      if (parsedStartDates[i].isAtSameMomentAs(_selectedStartDate)) {
        setState(() {
          _selectedIndex = i;
        });
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 320,
            height: 480,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a Date and Time',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSecondary),
                ),
                SizedBox(height: 24),
                Expanded(
                    child: ListView.separated(
                  itemCount: parsedStartDates.length,
                  separatorBuilder: (context, index) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final startDate = parsedStartDates[index];
                    final endDate = parsedEndDates[index];
                    final isSelected = (_selectedIndex == index);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                          _selectedStartDate = parsedStartDates[_selectedIndex!];
                          _selectedEndDate = parsedEndDates[_selectedIndex!];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ((_formatDate(startDate)).compareTo((_formatDate(endDate))) == 0)
                                  ? '${_formatDate(startDate)}'
                                  : '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_formatTime(startDate)} - ${_formatTime(endDate)}',
                              style: TextStyle(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Theme.of(context).colorScheme.onSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: MediaQuery.of(context).size.width * 0.045,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _selectedIndex != null
                          ? () {
                              // Handle setting the date
                              Navigator.of(context).pop({
                                'startDate': _selectedStartDate,
                                'endDate': _selectedEndDate,
                              });
                            }
                          : null,
                      child: Text(
                        'Set Date',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * .04,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor, // Background color
                        padding: EdgeInsets.symmetric(
                            vertical: MediaQuery.of(context).size.height * .0085,
                            horizontal: MediaQuery.of(context).size.width * 0.075),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0), // Rounded corners
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  Widget _buildAttendeeInfo(BuildContext context, bool isSmallScreen) {
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
                            eventId: widget.eventData!.eventId,
                            areFriends: false,
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: _buildInfoItem(context, '${widget.eventData!.attendees.length}', 'Attending', isSmallScreen),
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
                            eventId: widget.eventData!.eventId,
                            areFriends: true,
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: _buildInfoItem(context, '${widget.eventData!.friends.length}', 'Friends', isSmallScreen),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * .02),
        _buildInfoItem(context, '${widget.eventData!.numOfComments}', 'Comments', isSmallScreen),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String value, String label, bool isSmallScreen) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.069,
      width: MediaQuery.of(context).size.width * 0.29,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          width: 0.3,
          color: Color.fromARGB(200, 128, 122, 122),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * .0425,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width * .0415,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
        ],
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor, // Background color
              padding: EdgeInsets.symmetric(
                  vertical: MediaQuery.of(context).size.height * .01625,
                  horizontal: MediaQuery.of(context).size.width * 0.23),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0), // Rounded corners
              ),
            ),
            onPressed: () => _handleJoinLeaveAction(context, isHost, isAttending, currentUser),
            child: Text(
              buttonText,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width * .0475,
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
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
    final supabase = (await ref.read(supabaseInstance)).client;
    await attendeeLeaveEvent();
    await ref.read(profileProvider.notifier).deleteBlockedTime(null, widget.eventData.eventId);

    setState(() {
      widget.eventData.attending = false;
      widget.eventData.attendees.remove(supabase.auth.currentUser!.id);
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Left ${widget.eventData.title}")),
    );
  }

  void _joinEvent(BuildContext context, String currentUser) async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref.read(profileProvider.notifier).createBlockedTime(
          currentUser,
          _selectedStartDate.toString(),
          _selectedEndDate.toString(),
          widget.eventData.title,
          widget.eventData.eventId,
        );
    await attendeeJoinEvent();

    setState(() {
      widget.eventData.attending = true;
      widget.eventData.attendees.add(supabase.auth.currentUser!.id);
    });

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

  Future<void> attendeeJoinEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .joinEvent(supabase.auth.currentUser!.id, widget.eventData.eventId, _selectedStartDate, _selectedEndDate);
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
        'Check out this event: $link',
        subject: 'Event Link',
      );
    } else {
      print('Error: Unable to generate Branch link');
    }
  }

  Future<String?> generateBranchLink() async {
    try {
      BranchUniversalObject buo = BranchUniversalObject(
        canonicalIdentifier: 'event/${widget.eventData!.eventId}',
        title: widget.eventData!.title,
        imageUrl: widget.eventData!.imageUrl,
        contentDescription: widget.eventData!.description,
        keywords: [],
        publiclyIndex: true,
        locallyIndex: true,
        contentMetadata: BranchContentMetaData()..addCustomMetadata("event_id", widget.eventData!.eventId),
      );

      BranchLinkProperties lp = BranchLinkProperties(
        channel: 'app',
        feature: 'sharing',
        campaign: 'event_share',
        stage: 'user_share',
      )
        ..addControlParam('\$fallback_url', 'https://example.com')
        ..addControlParam('\$ios_url', 'https://apps.apple.com/app/id6505129089')
        ..addControlParam('\$android_url', 'https://play.google.com/store/apps/details?id=com.nomo.nomoapp');

      BranchResponse response = await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      if (response.success) {
        return response.result;
      } else {
        print('Error generating Branch link: ${response.errorMessage}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}

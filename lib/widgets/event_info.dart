import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:share/share.dart';

enum Options { itemOne, itemTwo, itemThree, itemFour }

class EventInfo extends ConsumerStatefulWidget {
  const EventInfo({Key? key, required this.eventsData, this.bookmarkSet}) : super(key: key);
  final Event eventsData;
  final bool? bookmarkSet;

  @override
  ConsumerState<EventInfo> createState() => _EventInfoState();
}

class _EventInfoState extends ConsumerState<EventInfo> {
  late bool bookmarkBool;

  @override
  void initState() {
    super.initState();
    bookmarkBool = widget.eventsData.bookmarked;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
    );
  }

  Widget _buildDateTimeInfo(BuildContext context, bool isSmallScreen) {
    final startDate = DateTime.parse(widget.eventsData.sdate);
    final endDate = DateTime.parse(widget.eventsData.edate);
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    var displayedDates;

    if(dateFormat.format(startDate) == dateFormat.format(endDate)) {
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
    return Row(
      children: [
        _buildInfoItem(context, '${widget.eventsData.attendees.length}', 'Attending', isSmallScreen),
        const SizedBox(width: 16),
        _buildInfoItem(context, '${widget.eventsData.friends.length}', 'Friends', isSmallScreen),
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
          final isHost = widget.eventsData.host == currentUser;
          final isAttending = widget.eventsData.attendees.any((attendee) => attendee is Map && attendee['user_id'] == currentUser);

          String buttonText = isHost ? 'Edit' : (isAttending ? 'Leave' : 'Join');

          return ElevatedButton(
            onPressed: () => _handleJoinLeaveAction(context, isHost, isAttending, currentUser),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
            ),
            child: Text(buttonText, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Are you sure you want to edit the event?',
          style: TextStyle(color: Theme.of(context).primaryColorDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: ((context) => NewEventScreen(
                      isNewEvent: false,
                      event: widget.eventsData,
                      isEdit: true,
                    )),
                  ))
                  .then((result) => Navigator.pop(context));
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  void _showLeaveEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure you want to leave the event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                attendeeLeaveEvent();
                ref
                    .read(profileProvider.notifier)
                    .deleteBlockedTime(null, widget.eventsData.eventId);
              });
              Navigator.pop(context);
            },
            child: const Text('YES'),
          ),
        ],
      ),
    );
  }

  void _joinEvent(BuildContext context, String currentUser) {
    ref
        .read(profileProvider.notifier)
        .createBlockedTime(
          currentUser,
          widget.eventsData.sdate,
          widget.eventsData.edate,
          widget.eventsData.title,
          widget.eventsData.eventId,
        );
    attendeeJoinEvent();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Joined ${widget.eventsData.title}")),
    );
  }

  Widget _buildBookmarkButton(BuildContext context) {
    return IconButton(
      onPressed: () => setState(() {
        bookmarkBool ? deBookmarkEvent() : bookmarkEvent();
        bookmarkBool = !bookmarkBool;
      }),
      icon: Icon(
        bookmarkBool ? Icons.bookmark : Icons.bookmark_border_outlined,
        color: Theme.of(context).colorScheme.onSecondary,
      ),
    );
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
    await ref
        .read(eventsProvider.notifier)
        .joinEvent(supabase.auth.currentUser!.id, widget.eventsData.eventId);
  }

  Future<void> attendeeLeaveEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(attendEventsProvider.notifier)
        .leaveEvent(widget.eventsData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> bookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .bookmark(widget.eventsData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> deBookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .unBookmark(widget.eventsData.eventId, supabase.auth.currentUser!.id);
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
        canonicalIdentifier: 'event/${widget.eventsData.eventId}',
        title: widget.eventsData.title,
        imageUrl: widget.eventsData.imageUrl,
        contentDescription: widget.eventsData.description,
        keywords: [],
        publiclyIndex: true,
        locallyIndex: true,
        contentMetadata: BranchContentMetaData()
          ..addCustomMetadata("event_id", widget.eventsData.eventId),
      );

      BranchLinkProperties lp = BranchLinkProperties(
        channel: 'app',
        feature: 'sharing',
        campaign: 'event_share',
        stage: 'user_share',
      )
        ..addControlParam('\$fallback_url', 'https://example.com')
        ..addControlParam('\$ios_url', 'https://apps.apple.com/app/id123456789')
        ..addControlParam('\$android_url',
            'https://play.google.com/store/apps/details?id=com.example.nomoapp');

      BranchResponse response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
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
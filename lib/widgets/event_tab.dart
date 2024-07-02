import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:nomo/screens/profile_screen.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends ConsumerStatefulWidget {
  const EventTab({Key? key, required this.eventData, this.bookmarkSet}) : super(key: key);

  final Event eventData;
  final bool? bookmarkSet;

  @override
  ConsumerState<EventTab> createState() => _EventTabState();
}

class _EventTabState extends ConsumerState<EventTab> {
  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.parse(widget.eventData.sdate);
    final formattedDate = "${date.month}/${date.day}/${date.year} at ${_getFormattedHour(date)}";

    return Card(
      color: Theme.of(context).canvasColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHostInfo(context),
          _buildEventImage(context),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventTitle(context),
                const SizedBox(height: 8),
                _buildEventDate(context, formattedDate),
                const SizedBox(height: 12),
                _buildEventLocation(context),
                const SizedBox(height: 16),
                EventInfo(eventsData: widget.eventData, bookmarkSet: widget.bookmarkSet),
                const SizedBox(height: 12),
                _buildEventDescription(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ProfileScreen(isUser: false, userId: widget.eventData.host),
        )),
        child: Row(
          children: [
            _buildHostAvatar(context),
            const SizedBox(width: 12),
            Text(
              widget.eventData.hostUsername,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
            radius: MediaQuery.of(context).devicePixelRatio *7,
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(widget.eventData.hostProfileUrl),
          );
        } else {
          return CircleAvatar(
            radius: MediaQuery.of(context).devicePixelRatio *7,
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
        child: FutureBuilder(
          future: ref.read(supabaseInstance),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Image.network(
                widget.eventData.imageUrl,
                fit: BoxFit.cover,
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _buildEventTitle(BuildContext context) {
    return Text(
      widget.eventData.title,
      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildEventDate(BuildContext context, String formattedDate) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          formattedDate,
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }

  Widget _buildEventLocation(BuildContext context) {
    return GestureDetector(
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

  String _getFormattedHour(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'P.M.' : 'A.M.';
    return '$hour $period';
  }
}
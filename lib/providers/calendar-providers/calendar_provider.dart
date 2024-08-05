import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';

final calendarStateProvider = StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
  return CalendarStateNotifier();
});

class CalendarState {
  final int monthDisplayed;
  final int yearDisplayed;
  final List<Event> attendingEvents;

  CalendarState({
    required this.monthDisplayed,
    required this.yearDisplayed,
    required this.attendingEvents,
  });

  CalendarState copyWith({
    int? monthDisplayed,
    int? yearDisplayed,
    List<Event>? attendingEvents,
  }) {
    return CalendarState(
      monthDisplayed: monthDisplayed ?? this.monthDisplayed,
      yearDisplayed: yearDisplayed ?? this.yearDisplayed,
      attendingEvents: attendingEvents ?? this.attendingEvents,
    );
  }
}

class CalendarStateNotifier extends StateNotifier<CalendarState> {
  CalendarStateNotifier()
      : super(CalendarState(
          monthDisplayed: DateTime.now().month,
          yearDisplayed: DateTime.now().year,
          attendingEvents: [],
        ));

  void updateMonth(int month) {
    state = state.copyWith(monthDisplayed: month);
  }

  void updateYear(int year) {
    state = state.copyWith(yearDisplayed: year);
  }

  void updateAttendingEvents(List<Event> events) {
    state = state.copyWith(attendingEvents: events);
  }
}

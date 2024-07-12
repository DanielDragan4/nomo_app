import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';


class AvailabilityProvider extends StateNotifier<List<Availability>?> {
  AvailabilityProvider({initialList}) : super(null);


  void updateAvailability(List<Availability> newList) async{
    state = newList;
  }
}

final availabilityProvider = StateNotifierProvider<AvailabilityProvider,List<Availability>?>((ref) {
  return AvailabilityProvider(initialList: []);
});

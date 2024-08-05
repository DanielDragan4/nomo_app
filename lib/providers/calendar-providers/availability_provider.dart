import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';


class AvailabilityProvider extends StateNotifier<List<Availability>?> {
  AvailabilityProvider({initialList}) : super(null);


  void updateAvailability(List<Availability> newList) async{
    /*
      takes in a new list of availability data to then set state of this provider

      Params: newList: List<Availability>
      
      Returns: none
    */
    state = newList;
  }
}

final availabilityProvider = StateNotifierProvider<AvailabilityProvider,List<Availability>?>((ref) {
  return AvailabilityProvider(initialList: []);
});

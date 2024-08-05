import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SessionProvider extends StateNotifier<List<String>?> {
  SessionProvider({initialSave}) : super(null);


  void changeSessionDataList() async{
    /*
      sets the state of the provider to the savedSession based on the phone

      Params: none
      
      Returns: none
    */
    final savedUserSessionData = await SharedPreferences.getInstance();
    state = savedUserSessionData.getStringList("savedSession");
  }
}

final savedSessionProvider = StateNotifierProvider<SessionProvider,List<String>?>((ref) {
  return SessionProvider(initialSave: null);
});

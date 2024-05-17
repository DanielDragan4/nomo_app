import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController searchController = TextEditingController();
      late List<bool> isSelected;

    @override
    void initState() {
        isSelected = [true, false, false];
        super.initState();
    }
  @override
  Widget build(BuildContext context,) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      body: Column(
        children: [
          SizedBox(
            //height: MediaQuery.of(context).devicePixelRatio *.07,
            //width: MediaQuery.of(context).devicePixelRatio*.75,
            child: Padding(
            padding: const EdgeInsets.fromLTRB(10,10,10,10),
            child:  SearchBar(
                controller: searchController,
                hintText: 'What are you looking for?',
                padding: const MaterialStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 12.0)),
                leading: const Icon(Icons.search),
              )
            ),
          ),
          ToggleButtons(
            constraints: const BoxConstraints(maxHeight: 250, minWidth: 90, maxWidth: 200),
                borderColor: Colors.black,
                fillColor: Theme.of(context).primaryColor,
                borderWidth: 1,
                selectedBorderColor: Colors.black,
                selectedColor: Colors.grey,
                borderRadius: BorderRadius.circular(15),
                onPressed: (int index) {
                    setState(() {
                    for (int i = 0; i < isSelected.length; i++) {
                        isSelected[i] = i == index;
                    }
                    });
                },
                isSelected: isSelected,
                children: const [
                    Padding(
                    padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                    child: Text(
                        'Events',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    )
                    ),
                    Padding(
                    padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                    child: Text(
                        'People',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    ),
                    Padding(
                    padding: EdgeInsets.fromLTRB(10, 3, 10, 3),
                    child: Text(
                        'Interests',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    )
                    ),
                ],
                ),
                const Divider()
        ],
      ),
    );
  }
}

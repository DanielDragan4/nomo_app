import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // body: SfCalendar(
        //   view: CalendarView.month,
        // ),
        );
  }
}
//     return ListView(
//       // Fixed extent scroll for each month
//       key: const PageStorageKey<String>('cal'),
//       physics: ClampingScrollPhysics( parent: ClampingScrollPhysics()),
//       children: List.generate(12, (monthIndex) {
//         // Generate days for the month
//         var year = currentDate.year;
//         var  month = currentDate.month;

//         final firstDayOfMonth = DateTime(year, monthIndex, 1);
//         var lastDayOfMonth = DateTime(year, monthIndex+2, 0).day;
        
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               getMonthName(monthIndex),
//               style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 28, fontWeight: FontWeight.bold),
//             ),
//             GridView.builder(
//               shrinkWrap: true,
//               physics: const NeverScrollableScrollPhysics(),
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 7,
//                 mainAxisSpacing: 0,
//                 crossAxisSpacing: 0,
//               ),
//               itemCount: lastDayOfMonth,
//               itemBuilder: (context, dayIndex) {
//                 return DateCell(dayOfMonth: dayIndex + 1);
//               },
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   String getMonthName(int monthIndex) {
//     switch (monthIndex) {
//       case 0:
//         return "January";
//       case 1:
//         return "February";
//       case 2:
//         return "March";
//       case 3:
//         return "April";
//       case 4:
//         return "May";
//       case 5:
//         return "June";
//       case 6:
//         return "July";
//       case 7:
//         return "August";
//       case 8:
//         return "September";
//       case 9:
//         return "October";
//       case 10:
//         return "November";
//       case 11:
//         return "December";
//       default:
//         return "Unknown";
//     }
//   }
// }

// class DateCell extends StatelessWidget {
//    const DateCell({super.key, required this.dayOfMonth});

//   final dayOfMonth;

//   @override
//   Widget build(BuildContext context) {
//     var strDay = dayOfMonth.toString();

//     return ElevatedButton(
//       onPressed: (){},
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.grey[200],
//         shape: BeveledRectangleBorder(),
//       ),
//       child: Text(
//         strDay,
//         softWrap: false,
//         textAlign: TextAlign.left,
//         style: TextStyle(
//           color: Colors.black,
//           fontSize: MediaQuery.of(context).size.width * 0.022 
//         ),
//       )
//     );
//   }
// }
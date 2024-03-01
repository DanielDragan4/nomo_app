import 'package:flutter/material.dart';

class Month extends StatelessWidget {
   Month(
      {super.key,
      required this.selectedMonth,
      required this.eventsByDate,
      required this.firstDayOfWeek,
      required this.lastOfMonth,
      required this.yearDisplayed});

  final int selectedMonth;
  final eventsByDate;
  final int firstDayOfWeek;
  final int lastOfMonth;
  int cellIndex = 0;
  final int yearDisplayed;

  String monthName(int month) {
    switch(month) {
      case 1: return "January";
      case 2: return "Febuary";
      case 3: return "March";
      case 4: return "April";
      case 5: return "May";
      case 6: return "June";
      case 7: return "July";
      case 8: return "August";
      case 9: return "September";
      case 10: return "October";
      case 11: return "November";
      case 12: return "December";
    }
    return "";
  }
  
  bool findBoarderWidth(cellPosition) {
    bool boarderWidth;

    if ((cellIndex-firstDayOfWeek) < lastOfMonth && (cellIndex-firstDayOfWeek) >= 0) {
      boarderWidth = true;
      } 
    else {
      boarderWidth = false;
    }

    return boarderWidth;
  }
  Color findCellColor(cellPosition) {

    Color cellColor;
    if((cellIndex-firstDayOfWeek) < lastOfMonth && (cellIndex-firstDayOfWeek) >= 0) {
      cellColor = const Color.fromARGB(255, 221, 221, 221);    
      } 
    else {
      cellColor = const Color.fromARGB(0, 255, 255, 255);
    }

    return cellColor;
  }

  String daysOfMonth() {

    String dayToDisplay;

    if((cellIndex-firstDayOfWeek) < lastOfMonth && (cellIndex-firstDayOfWeek) >= 0) {
      dayToDisplay = "${(cellIndex-firstDayOfWeek) + 1} ";
    } 
    else {
      dayToDisplay = '';
    }

    cellIndex++;
    return dayToDisplay;
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                    "${monthName(selectedMonth)} $yearDisplayed",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                      
                    ),
                  ),
              ),
              Expanded(
                  child: GridView.builder( 
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7),
                    itemCount: 42, 
                    itemBuilder: (context, index) => DayButton(
                      isSelected: false,
                      boarderWidth: findBoarderWidth(index),
                      cellColor: findCellColor(index),
                      dayDisplayed: daysOfMonth(),
                    ),
                  ),
              ),
            ],
          )
        ),
    );
  }
}

class DayButton extends StatelessWidget {
  const DayButton({
    super.key,
    required this.isSelected,
    required this.boarderWidth,
    required this.cellColor,
    required this.dayDisplayed,
    //required this.onPressed,
  });

  final bool isSelected;
  final bool boarderWidth;
  final Color cellColor;
  final String dayDisplayed;
  //final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
        onTap: () {},
          child: Container(
            height: MediaQuery.sizeOf(context).height*0.0628,
            alignment: Alignment.topRight,
              decoration: BoxDecoration(
                border: boarderWidth ? Border.all(width: 1) : Border.all(color: const Color.fromARGB(0, 255, 255, 255)),
                color:  cellColor,
              ),
                  child:Text(dayDisplayed ,style: const TextStyle(fontSize: 20),),  
                ),
      ),
      ],
    );
  }
}

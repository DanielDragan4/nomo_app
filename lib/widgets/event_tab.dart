import 'package:flutter/material.dart';

class EventTab extends StatelessWidget {
  const EventTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Color.fromARGB(255, 26, 34, 38), width: 2,)
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
              ),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset('assets/images/squat.jpg', fit: BoxFit.fill,),
    
              ),
            ),
            Container(
              height: 100,
            )
          ],
        ),
      ),
    );
  }
}

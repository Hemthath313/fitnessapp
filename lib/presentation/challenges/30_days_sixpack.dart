import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SixPackChallengeScreen extends StatelessWidget {
  final int dayNumber;

  const SixPackChallengeScreen({required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Day $dayNumber - Six-Pack Challenge')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('Challenges/SixPackChallenge/Day $dayNumber')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          var exercises = snapshot.data!.docs;

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              var exercise = exercises[index].data();
              return ListTile(
                title: Text(exercise['name']),
                subtitle: Text('${exercise['sets']} x ${exercise['reps']}'),
                trailing: Checkbox(
                  value: exercise['completed'],
                  onChanged: (val) {
                    FirebaseFirestore.instance
                        .collection(
                            'Challenges/SixPackChallenge/Day $dayNumber')
                        .doc(exercise['id'])
                        .update({'completed': val});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

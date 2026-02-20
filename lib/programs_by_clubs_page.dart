import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgramsByClubsPage extends StatelessWidget {
  const ProgramsByClubsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Programs by Clubs"),
        backgroundColor: const Color(0xFF009639),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("clubs").snapshots(),
        builder: (context, clubSnapshot) {
          if (!clubSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clubs = clubSnapshot.data!.docs;

          if (clubs.isEmpty) {
            return const Center(child: Text("No clubs found"));
          }

          return ListView.builder(
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final clubData = clubs[index];
              final clubName = clubData.id;

              return ExpansionTile(
                title: Text(clubName),
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("clubs")
                        .doc(clubName)
                        .collection("programs")
                        .orderBy("dateTime")
                        .snapshots(),
                    builder: (context, programSnapshot) {
                      if (!programSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final programs = programSnapshot.data!.docs;

                      if (programs.isEmpty) {
                        return const ListTile(
                          title: Text("No programs yet"),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: programs.length,
                        itemBuilder: (context, i) {
                          final program =
                              programs[i].data() as Map<String, dynamic>;
                          final title = program["title"] ?? "";
                          final desc = program["description"] ?? "";
                          final dateTime =
                              (program["dateTime"] as Timestamp).toDate();

                          return ListTile(
                            title: Text(title),
                            subtitle: Text(
                                "$desc\n${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}"),
                          );
                        },
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class StudentJournalEntries extends StatefulWidget {
  const StudentJournalEntries({super.key});

  @override
  State<StudentJournalEntries> createState() => _StudentJournalEntriesState();
}

class _StudentJournalEntriesState extends State<StudentJournalEntries> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Journal Entries')),
    );
  }
}

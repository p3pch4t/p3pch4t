import 'package:flutter/material.dart';
import 'package:p3pch4t/main.dart';

class QueuedEventsPage extends StatefulWidget {
  const QueuedEventsPage({super.key});

  @override
  State<QueuedEventsPage> createState() => _QueuedEventsPageState();
}

class _QueuedEventsPageState extends State<QueuedEventsPage> {
  final queuedEvents = p3p.getQueuedEvents();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Queued Events')),
      body: ListView.builder(
        itemCount: queuedEvents.length,
        itemBuilder: (context, index) {
          final evt = queuedEvents[index];
          return Card(
            child: ListTile(
              title: Text('#${evt.id}. ${evt.endpoint}'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) {
                      return const QueuedEventPage();
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class QueuedEventPage extends StatelessWidget {
  const QueuedEventPage({super.key, this.queueEvent});
  final dynamic queueEvent;

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

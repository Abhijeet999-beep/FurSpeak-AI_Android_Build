import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestoreScreen extends StatefulWidget {
  const TestFirestoreScreen({super.key});

  @override
  State<TestFirestoreScreen> createState() => _TestFirestoreScreenState();
}

class _TestFirestoreScreenState extends State<TestFirestoreScreen> {

  Future<void> writeData() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'message': 'Hello from FurSpeak AI 🐶',
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ WRITE SUCCESS");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Write Success ✅")),
      );

    } catch (e) {
      print("❌ WRITE ERROR: $e");
    }
  }

  Future<void> readData() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection('test').get();

      for (var doc in snapshot.docs) {
        print(doc.data());
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Read Success 📥")),
      );

    } catch (e) {
      print("❌ READ ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Firestore Test")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            ElevatedButton(
              onPressed: writeData,
              child: const Text("Write Data"),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: readData,
              child: const Text("Read Data"),
            ),

          ],
        ),
      ),
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/log_entry_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> uploadLogEntries(String userId, String logDate, List<LogEntry> entries) async {
    final userDoc = _firestore.collection('users').doc(userId);

    for (LogEntry entry in entries) {
      await userDoc.collection(logDate).add(entry.toJson());
    }
  }
}

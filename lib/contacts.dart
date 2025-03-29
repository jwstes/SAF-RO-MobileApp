/* import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact/contact.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactService {
  Future<bool> requestContactPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      print("✅ Contact permission granted.");
      return true;
    } else {
      print("❌ Contact permission denied.");
      return false;
    }
  }

  Future<List<Map<String, String>>> fetchContacts() async {
    final granted = await requestContactPermission();
    if (!granted) return [];

    try {
      final contacts = await Contacts.streamContacts().toList();
      return contacts.map((contact) {
        final name = contact.displayName ?? 'Unnamed';
        final phone = contact.phones.isNotEmpty ? contact.phones.first.number : 'No Number';
        return {'name': name, 'phone': phone};
      }).toList();
    } catch (e) {
      print("❌ Error fetching contacts: $e");
      return [];
    }
  }
} */

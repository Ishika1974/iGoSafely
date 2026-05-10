import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_model.dart';

class ContactsManagementDialog extends StatefulWidget {
  const ContactsManagementDialog({super.key});

  @override
  State<ContactsManagementDialog> createState() => _ContactsManagementDialogState();
}

class _ContactsManagementDialogState extends State<ContactsManagementDialog> {
  final List<EmergencyContact> _contacts = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final user = await UserModel.getCurrentUser();
    if (user != null) {
      setState(() {
        _contacts.clear();
        _contacts.addAll(user.emergencyContacts);
      });
    }
  }

  Future<void> _addContact() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty) return;

    setState(() {
      _contacts.add(EmergencyContact(
        name: _nameController.text,
        phone: _phoneController.text,
      ));
    });

    _nameController.clear();
    _phoneController.clear();
    
    // Save to SharedPreferences (sync with Firestore in production)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts', 
        _contacts.map((c) => '${c.name}|${c.phone}').toList());
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact added successfully!')),
      );
    }
  }

  Future<void> _removeContact(int index) async {
    setState(() {
      _contacts.removeAt(index);
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('emergency_contacts', 
        _contacts.map((c) => '${c.name}|${c.phone}').toList());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE91E63),
              ),
            ),
            const SizedBox(height: 20),
            
            // Add Contact Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add Contact', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Contacts List
            Expanded(
              child: _contacts.isEmpty
                  ? const Center(
                      child: Text(
                        'No contacts added\nAdd your emergency contacts',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFE91E63),
                              child: Text(
                                contact.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(contact.name),
                            subtitle: Text(contact.phone),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeContact(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
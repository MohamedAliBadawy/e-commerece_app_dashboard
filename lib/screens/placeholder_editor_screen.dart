import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlaceholderEditorScreen extends StatefulWidget {
  @override
  _PlaceholderEditorScreenState createState() =>
      _PlaceholderEditorScreenState();
}

class _PlaceholderEditorScreenState extends State<PlaceholderEditorScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _outerController;
  late TextEditingController _innerController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _outerController = TextEditingController();
    _innerController = TextEditingController();
  }

  @override
  void dispose() {
    _outerController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  Future<void> _savePlaceholders() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _firestore.collection('widgets').doc('placeholders').set({
        'outerPlaceholderText': _outerController.text,
        'innerPlaceholderText': _innerController.text,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Placeholders updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving placeholders: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Placeholder Texts')),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            _firestore.collection('widgets').doc('placeholders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildForm('', '');
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          _outerController.text = data['outerPlaceholderText'] ?? '';
          _innerController.text = data['innerPlaceholderText'] ?? '';

          return _buildForm(
            data['outerPlaceholderText'] ?? '',
            data['innerPlaceholderText'] ?? '',
          );
        },
      ),
    );
  }

  Widget _buildForm(String outerText, String innerText) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _outerController,
              decoration: InputDecoration(
                labelText: 'Outer Placeholder Text',
                border: OutlineInputBorder(),
                hintText: 'Enter outer placeholder text',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _innerController,
              decoration: InputDecoration(
                labelText: 'Inner Placeholder Text',
                border: OutlineInputBorder(),
                hintText: 'Enter inner placeholder text',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _savePlaceholders,
              child:
                  _isSaving
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}

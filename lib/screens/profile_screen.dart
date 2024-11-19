import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool _isLoading = false;

  // User data
  String? _email;
  String? _displayName;
  String? _dob;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userData = await _firestoreService.getUserData(user.uid);
      setState(() {
        _email = user.email;
        _displayName = userData['displayName'] ?? user.email;
        _dob = userData['dob'];
        _displayNameController.text = _displayName ?? '';
        _dobController.text = _dob ?? '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update user profile
  Future<void> _updateProfile() async {
    final displayName = _displayNameController.text.trim();
    final dob = _dobController.text.trim();
    final user = _auth.currentUser;

    if (user == null || displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Display name cannot be empty.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.updateUserProfile(user.uid, displayName, dob);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    await _authService.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProfileField('Email', _email ?? '', readOnly: true),
                  SizedBox(height: 16),
                  _buildProfileField(
                    'Display Name',
                    _displayNameController.text,
                    controller: _displayNameController,
                  ),
                  SizedBox(height: 16),
                  _buildProfileField(
                    'Date of Birth',
                    _dobController.text,
                    controller: _dobController,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: Text('Save Changes'),
                  ),
                ],
              ),
            ),
    );
  }

  // Profile field widget
  Widget _buildProfileField(
    String label,
    String value, {
    TextEditingController? controller,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }
}

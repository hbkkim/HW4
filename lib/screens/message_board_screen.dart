import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class MessageBoardScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  const MessageBoardScreen({Key? key, required this.boardId, required this.boardName})
      : super(key: key);

  @override
  _MessageBoardScreenState createState() => _MessageBoardScreenState();
}

class _MessageBoardScreenState extends State<MessageBoardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  // Send message function
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    final user = _auth.currentUser;

    if (messageText.isEmpty || user == null) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _firestoreService.addMessage(
        widget.boardId,
        user.uid,
        user.displayName ?? user.email ?? 'Anonymous',
        messageText,
      );
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  // Build message list
  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getMessages(widget.boardId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No messages yet. Start the conversation!'));
        }

        final messages = snapshot.data!.docs;

        return ListView.builder(
          reverse: true,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final messageText = message['message'] ?? '';
            final username = message['username'] ?? 'Anonymous';
            final timestamp = message['timestamp']?.toDate() ?? DateTime.now();

            return ListTile(
              title: Text(
                username,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(messageText),
              trailing: Text(
                '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.boardName),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  // Message input field
  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(width: 8),
          _isSending
              ? CircularProgressIndicator()
              : IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
        ],
      ),
    );
  }
}

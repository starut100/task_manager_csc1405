import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBUbOcyv0YqXmuHSv53djv382kbHnt8Vm8",
      authDomain: "task-manager-csc1405.firebaseapp.com",
      projectId: "task-manager-csc1405",
      storageBucket: "task-manager-csc1405.firebasestorage.app",
      messagingSenderId: "615126923173",
      appId: "1:615126923173:web:299c5d220ae9415adf1a4c",
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFFFBF8FF),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _handleLogin() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('⚠️ Front-end Alert: Fields cannot be empty!', Colors.amber);
      return;
    }

    setState(() { _isLoggingIn = true; });

    try {
      if (username.length < 3 || password.length < 4) {
        throw Exception("Invalid input constraints.");
      }

      String hashedPassword = _hashPassword(password);
      String correctHashedPassword = _hashPassword("1234");

      if (username == "admin" && hashedPassword == correctHashedPassword) {
        print("ℹ️ [LOG]: User '$username' logged in successfully at ${DateTime.now()}");

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TaskHomeScreen(username: username)),
        );
      } else {
        _showSnackBar('❌ Invalid username or password!', Colors.redAccent);
      }
    } catch (e) {
      print("Error: $e");
      _showSnackBar('❌ Login request rejected by server constraints.', Colors.red);
    } finally {
      setState(() { _isLoggingIn = false; });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400), //  التعديل الصحيح هنا
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 60, color: Colors.purple),
              const SizedBox(height: 16),
              const Text('Student Task Manager', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 8),
              const Text('Sign in to manage your academic tasks', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username (use: admin)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password (use: 1234)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              _isLoggingIn
                  ? const CircularProgressIndicator(color: Colors.purple)
                  : SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD1C4E9)),
                  child: const Text('Login', style: TextStyle(color: Colors.purple, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskHomeScreen extends StatefulWidget {
  final String username;
  const TaskHomeScreen({super.key, required this.username});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('tasks');
  bool _isLoading = false;

  void _addTask() async {
    String taskText = _taskController.text.trim();

    if (taskText.isEmpty) {
      _showSnackBar('⚠️ Cannot add an empty task!', Colors.amber);
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (taskText.length > 100) {
        throw Exception("Payload too large.");
      }

      await _tasksCollection.add({
        'title': taskText,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': widget.username,
      });

      _taskController.clear();
      _showSnackBar('✅ Task saved to cloud successfully!', Colors.green);
    } catch (e) {
      print("Database Error: $e");
      _showSnackBar('❌ Connection timeout. Try again.', Colors.red);
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _deleteTask(String docId) async {
    try {
      await _tasksCollection.doc(docId).delete();
      _showSnackBar('🗑️ Task removed.', Colors.grey[800]!);
    } catch (e) {
      _showSnackBar('❌ Failed to delete task.', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.username}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFFD1C4E9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'Enter new task...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _isLoading
                    ? const CircularProgressIndicator(color: Colors.purple)
                    : ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF3E5F5),
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.add, color: Colors.purple),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _tasksCollection.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Database error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.purple));
                }
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tasks available. Add some!', style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteTask(doc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

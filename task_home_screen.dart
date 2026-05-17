import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskHomeScreen extends StatefulWidget {
  const TaskHomeScreen({super.key});

  @override
  State<TaskHomeScreen> createState() => _TaskHomeScreenState();
}

class _TaskHomeScreenState extends State<TaskHomeScreen> {
  // أداة للتحكم بالنص المكتوب داخل خانة إضافة المهمة
  final TextEditingController _taskController = TextEditingController();

  // الوصول لمجموعة (Collection) المهام داخل Cloud Firestore السحابي
  final CollectionReference _tasksCollection =
  FirebaseFirestore.instance.collection('tasks');

  // دالة برمجية لإضافة مهمة جديدة إلى السيرفر
  void _addNewTask() async {
    if (_taskController.text.trim().isNotEmpty) {
      await _tasksCollection.add({
        'title': _taskController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(), // ترتيب المهام حسب الوقت تلقائياً
      });
      _taskController.clear(); // مسح الخانة بعد الإضافة بنجاح
    }
  }

  // دالة برمجية لحذف المهمة عند الضغط على أيقونة السلة
  void _deleteTask(String id) async {
    await _tasksCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // قسم إدخال المهمة الجديدة (حقل نصي + زر)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter new task...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addNewTask,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // قسم عرض المهام المربوط تلقائياً بالسيرفر السحابي (Live Sync)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _tasksCollection.orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  // حالة انتظار تحميل البيانات في البداية
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // حالة عدم وجود أي مهام مضافة في السيرفر حالياً
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No tasks available. Add some!',
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    );
                  }

                  // تكرار وعرض البيانات المجلوبة داخل قائمة مرنة
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var taskDoc = snapshot.data!.docs[index];
                      String taskId = taskDoc.id;
                      String taskTitle = taskDoc['title'] ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(taskTitle, style: const TextStyle(fontSize: 16)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _deleteTask(taskId),
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
      ),
    );
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }
}
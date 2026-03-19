import 'package:flutter/material.dart';
import 'services/database_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final data = await DatabaseHelper.instance.getNotes();
    setState(() {
      notes = data;
    });
  }

  void _showDialog({Map<String, dynamic>? note}) {
    final title = TextEditingController(text: note?['title'] ?? '');
    final content = TextEditingController(text: note?['content'] ?? '');
    final deadline = TextEditingController(text: note?['deadline'] ?? '');
    final tagInput = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(note == null ? 'เพิ่มโน๊ต' : 'แก้ไขโน๊ต'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'หัวข้อ')),
              TextField(controller: content, decoration: const InputDecoration(labelText: 'เนื้อหา')),
              TextField(controller: deadline, decoration: const InputDecoration(labelText: 'Deadline')),
              TextField(controller: tagInput, decoration: const InputDecoration(labelText: 'Tag (พิมพ์ทีละอัน)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              if (title.text.isEmpty) return;

              final now = DateTime.now().toString();

              int noteId;

              if (note == null) {
                noteId = await DatabaseHelper.instance.insertNote({
                  'title': title.text,
                  'content': content.text,
                  'createdAt': now,
                  'deadline': deadline.text,
                });
              } else {
                noteId = note['id'];
              }

              if (tagInput.text.isNotEmpty) {
                int tagId = await DatabaseHelper.instance.insertTag(tagInput.text);
                await DatabaseHelper.instance.addTagToNote(noteId, tagId);
              }

              if (mounted) Navigator.pop(context);
              _loadNotes();
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(int id) async {
    await DatabaseHelper.instance.deleteNote(id);
    _loadNotes();
  }

  Future<List<Map<String, dynamic>>> _getTags(int noteId) async {
    return await DatabaseHelper.instance.getTagsByNote(noteId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SQLite Notes')),
      body: notes.isEmpty
          ? const Center(child: Text('ยังไม่มีข้อมูล'))
          : ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, i) {
                final n = notes[i];

                return FutureBuilder(
                  future: _getTags(n['id']),
                  builder: (context, snapshot) {
                    List tags = snapshot.data ?? [];

                    return Card(
                      child: ListTile(
                        title: Text(n['title']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['content']),
                            Text("Deadline: ${n['deadline'] ?? '-'}"),
                            Wrap(
                              children: tags.map((t) {
                                return Chip(label: Text(t['name']));
                              }).toList(),
                            ),
                          ],
                        ),
                        onTap: () => _showDialog(note: n),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(n['id']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
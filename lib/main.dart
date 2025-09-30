import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// API Setup 
const String apiKey = "4a3751fa-fbdb-4058-8f31-3a5824d7a82c";
const String baseUrl = "https://todoapp-api.apps.k8s.gu.se/todos";

String buildUrl([String path = ""]) {
  if (path.isNotEmpty) {
    return "$baseUrl/$path?key=$apiKey";
  }
  return "$baseUrl?key=$apiKey";
}

class Todo {
  final String id;
  final String title;
  final bool done;

  Todo({required this.id, required this.title, required this.done});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json["id"],
      title: json["title"],
      done: json["done"] is bool ? json["done"] : json["done"] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {"title": title, "done": done};
  }
}

class TodoProvider extends ChangeNotifier {
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;

  Future<void> fetchTodos() async {
    final res = await http.get(Uri.parse(buildUrl()));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      _todos = data.map((e) => Todo.fromJson(e)).toList();
      notifyListeners();
    } else {
      debugPrint("Fetch failed: ${res.body}");
    }
  }

  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return;
    final res = await http.post(
      Uri.parse(buildUrl()),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"title": title, "done": false}),
    );
    if (res.statusCode == 200) {
      await fetchTodos();
    } else {
      debugPrint("Add failed: ${res.body}");
    }
  }

  Future<void> updateTodo(Todo todo) async {
    final res = await http.put(
      Uri.parse(buildUrl(todo.id)),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(todo.toJson()),
    );
    if (res.statusCode == 200) {
      await fetchTodos();
    } else {
      debugPrint("Update failed: ${res.body}");
    }
  }

  Future<void> deleteTodo(String id) async {
    final res = await http.delete(Uri.parse(buildUrl(id)));
    if (res.statusCode == 200) {
      await fetchTodos();
    } else {
      debugPrint("Delete failed: ${res.body}");
    }
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoProvider()..fetchTodos(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Todo App by Guiswulfsem",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: "Todo App by Guswulfsem"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add New Task"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddTodoPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            /// Todo list
            Expanded(
              child: ListView.builder(
                itemCount: todoProvider.todos.length,
                itemBuilder: (context, index) {
                  final todo = todoProvider.todos[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          decoration: todo.done
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Toggle done
                          IconButton(
                            icon: Icon(
                              todo.done
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              todoProvider.updateTodo(
                                Todo(
                                  id: todo.id,
                                  title: todo.title,
                                  done: !todo.done,
                                ),
                              );
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                            },
                          ),

                          /// Delete
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => todoProvider.deleteTodo(todo.id),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ==== Add Todo Page ====
class AddTodoPage extends StatefulWidget {
  const AddTodoPage({super.key});

  @override
  State<AddTodoPage> createState() => _AddTodoPageState();
}

class _AddTodoPageState extends State<AddTodoPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text("Add New Todo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Enter task title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.isNotEmpty) {
                  await todoProvider.addTodo(_controller.text);
                  Navigator.pop(context); // go back after adding
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}

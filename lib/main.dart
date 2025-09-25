import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String apiKey = "4a3751fa-fbdb-4058-8f31-3a5824d7a82c";
const String baseUrl = "https://todoapp-api.apps.k8s.gu.se/todos";

// API key so i dont need to type it out every time
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
    return {
      "title": title,
      "done": done,
    };
  }
}

void main() {
  runApp(const MyApp());
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
  List<Todo> todoList = [];
  final TextEditingController taskController = TextEditingController();
  int updateIndex = -1;

  // Fetch todos
  Future<void> fetchTodos() async {
    final res = await http.get(Uri.parse(buildUrl()));
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      setState(() {
        todoList = data.map((e) => Todo.fromJson(e)).toList();
      });
    } else {
      debugPrint("Fetch failed: ${res.body}");
    }
  }

  // Add todo
  Future<void> addTodo(String title) async {
    if (title.trim().isEmpty) return; // prevent null/empty sends
    final body = {"title": title.trim(), "done": false};
    debugPrint("Sending addTodo: $body");
    final res = await http.post(
      Uri.parse(buildUrl()),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );
    if (res.statusCode == 200) {
      await fetchTodos();
    } else {
      debugPrint("Add failed: ${res.body}");
    }
  }

  // Update todo
  Future<void> updateTodo(Todo todo) async {
    if (todo.title.trim().isEmpty) return; // prevent null/empty sends
    debugPrint("Sending updateTodo: ${todo.toJson()}");
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

  // Delete todo
  Future<void> deleteTodo(String id) async {
    final res = await http.delete(Uri.parse(buildUrl(id)));
    if (res.statusCode == 200) {
      await fetchTodos();
    } else {
      debugPrint("Delete failed: ${res.body}");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchTodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input + button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      hintText: "Enter a task",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (taskController.text.isNotEmpty) {
                      if (updateIndex == -1) {
                        addTodo(taskController.text);
                      } else {
                        final todo = todoList[updateIndex];
                        updateTodo(Todo(
                          id: todo.id,
                          title: taskController.text,
                          done: todo.done,
                        ));
                        setState(() {
                          updateIndex = -1;
                        });
                      }
                      taskController.clear();
                    }
                  },
                  child: Text(updateIndex == -1 ? "Add" : "Update"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Todo list
            Expanded(
              child: ListView.builder(
                itemCount: todoList.length,
                itemBuilder: (context, index) {
                  final todo = todoList[index];
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
                          IconButton(
                            icon: Icon(
                              todo.done
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: Colors.green,
                            ),
                            onPressed: () {
                              updateTodo(Todo(
                                id: todo.id,
                                title: todo.title,
                                done: !todo.done,
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              setState(() {
                                taskController.text = todo.title;
                                updateIndex = index;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteTodo(todo.id),
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

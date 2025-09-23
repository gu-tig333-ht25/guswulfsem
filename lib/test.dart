import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ---------------- CONFIG ----------------
const String baseUrl = "https://todoapp-api.apps.k8s.gu.se";
const String apiKey = "YOUR_API_KEY_HERE"; // get from /register

class Todo {
  final String id;
  final String title;
  final bool done;

  Todo({required this.id, required this.title, required this.done});

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      title: json['title'],
      done: json['done'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'done': done,
    };
  }
}

// ---------------- API ----------------
Future<List<Todo>> fetchTodos() async {
  final res = await http.get(Uri.parse("$baseUrl/todos?key=$apiKey"));
  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.map((json) => Todo.fromJson(json)).toList();
  } else {
    throw Exception("Failed to fetch todos");
  }
}

Future<List<Todo>> addTodoApi(String title) async {
  final res = await http.post(
    Uri.parse("$baseUrl/todos?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"title": title, "done": false}),
  );
  if (res.statusCode == 200) {
    final List data = jsonDecode(res.body);
    return data.map((json) => Todo.fromJson(json)).toList();
  } else {
    throw Exception("Failed to add todo");
  }
}

Future<Todo> updateTodoApi(Todo todo) async {
  final res = await http.put(
    Uri.parse("$baseUrl/todos/${todo.id}?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(todo.toJson()),
  );
  if (res.statusCode == 200) {
    return Todo.fromJson(jsonDecode(res.body));
  } else {
    throw Exception("Failed to update todo");
  }
}

Future<void> deleteTodoApi(String id) async {
  final res = await http.delete(Uri.parse("$baseUrl/todos/$id?key=$apiKey"));
  if (res.statusCode != 200) {
    throw Exception("Failed to delete todo");
  }
}

// ---------------- APP ----------------
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Todo App by Guswulfsem",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: MyHomePage(title: "Todo App by Guswulfsem"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final TextEditingController taskController = TextEditingController();
int updateIndex = -1;

class _MyHomePageState extends State<MyHomePage> {
  List<Todo> todoList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTodos();
  }

  void showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void loadTodos() async {
    try {
      final todos = await fetchTodos();
      setState(() {
        todoList = todos;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showError(context, e.toString());
    }
  }

  void addTask(String task) async {
    try {
      final updatedList = await addTodoApi(task);
      setState(() => todoList = updatedList);
      taskController.clear();
    } catch (e) {
      showError(context, e.toString());
    }
  }

  void updateTask(String task, int index) async {
    try {
      final updated = Todo(
        id: todoList[index].id,
        title: task,
        done: todoList[index].done,
      );
      final result = await updateTodoApi(updated);
      setState(() => todoList[index] = result);
      updateIndex = -1;
      taskController.clear();
    } catch (e) {
      showError(context, e.toString());
    }
  }

  void toggleDone(int index) async {
    try {
      final updated = Todo(
        id: todoList[index].id,
        title: todoList[index].title,
        done: !todoList[index].done,
      );
      final result = await updateTodoApi(updated);
      setState(() => todoList[index] = result);
    } catch (e) {
      showError(context, e.toString());
    }
  }

  void deleteTask(int index) async {
    try {
      await deleteTodoApi(todoList[index].id);
      setState(() => todoList.removeAt(index));
    } catch (e) {
      showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // input field + button
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
                        addTask(taskController.text);
                      } else {
                        updateTask(taskController.text, updateIndex);
                      }
                    }
                  },
                  child: Text(updateIndex == -1 ? "Add" : "Update"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // tasks list or loader
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : todoList.isEmpty
                      ? const Center(child: Text("No tasks yet!"))
                      : ListView.builder(
                          itemCount: todoList.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  todoList[index].title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    decoration: todoList[index].done
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        todoList[index].done
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => toggleDone(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        setState(() {
                                          taskController.text =
                                              todoList[index].title;
                                          updateIndex = index;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => deleteTask(index),
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

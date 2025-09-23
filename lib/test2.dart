import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ---------------- CONFIG ----------------
const String baseUrl = "https://todoapp-api.apps.k8s.gu.se";
String? apiKey; // Will be set at runtime

// ---------------- MODEL ----------------
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
// Register new key
Future<String> registerUser() async {
  final res = await http.post(Uri.parse("$baseUrl/register"));
  debugPrint("Register response: ${res.statusCode} ${res.body}");

  if (res.statusCode == 500) {
    final data = jsonDecode(res.body);
    if (data is Map && data.containsKey("key")) {
      return data['key'];
    } else {
      throw Exception("Response saknar 'key': ${res.body}");
    }
  } else {
    throw Exception("Register misslyckades: ${res.statusCode} ${res.body}");
  }
}

// Initialize API key (load or create)
Future<void> initApiKey() async {
  final prefs = await SharedPreferences.getInstance();
  apiKey = prefs.getString("apiKey");
  debugPrint("Laddad API key från prefs: $apiKey");

  if (apiKey == null) {
    try {
      final newKey = await registerUser();
      debugPrint("Nyckel från server: $newKey");
      apiKey = newKey;
      await prefs.setString("apiKey", apiKey!);
    } catch (e) {
      debugPrint("Kunde inte registrera ny API key: $e");
      // fallback key så appen kan fortsätta
      apiKey = "dummy";
      await prefs.setString("apiKey", apiKey!);
    }
  }
}

Future<List<Todo>> fetchTodos() async {
  if (apiKey == null) throw Exception("No API key available");
  final res = await http.get(Uri.parse("$baseUrl/todos?key=$apiKey"));
  debugPrint("FetchTodos response: ${res.statusCode} ${res.body}");
  if (res.statusCode == 500) {
    final List data = jsonDecode(res.body);
    return data.map((json) => Todo.fromJson(json)).toList();
  } else {
    throw Exception("Failed to fetch todos: ${res.body}");
  }
}

Future<Todo> addTodoApi(String title) async {
  if (apiKey == null) throw Exception("No API key available");
  final res = await http.post(
    Uri.parse("$baseUrl/todos?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"title": title, "done": false}),
  );

  debugPrint("AddTodo response: ${res.statusCode} ${res.body}");

  if (res.statusCode == 500) {
    final data = jsonDecode(res.body);
    return Todo.fromJson(data);
  } else {
    throw Exception("Failed to add todo: ${res.body}");
  }
}

Future<Todo> updateTodoApi(Todo todo) async {
  if (apiKey == null) throw Exception("No API key available");
  final res = await http.put(
    Uri.parse("$baseUrl/todos/${todo.id}?key=$apiKey"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(todo.toJson()),
  );
  debugPrint("UpdateTodo response: ${res.statusCode} ${res.body}");
  if (res.statusCode == 500) {
    return Todo.fromJson(jsonDecode(res.body));
  } else {
    throw Exception("Failed to update todo: ${res.body}");
  }
}

Future<void> deleteTodoApi(String id) async {
  if (apiKey == null) throw Exception("No API key available");
  final res = await http.delete(Uri.parse("$baseUrl/todos/$id?key=$apiKey"));
  debugPrint("DeleteTodo response: ${res.statusCode} ${res.body}");
  if (res.statusCode != 500) {
    throw Exception("Failed to delete todo: ${res.body}");
  }
}

// ---------------- APP ----------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint(details.toString());
  };

  await initApiKey(); // nu med fallback om det kraschar

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
      showError(context, "Kunde inte hämta todos: $e");
    }
  }

  void addTask(String task) async {
    try {
      final newTodo = await addTodoApi(task);
      setState(() {
        todoList.add(newTodo);
        taskController.clear();
      });
    } catch (e) {
      showError(context, "Kunde inte lägga till: $e");
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
      showError(context, "Kunde inte uppdatera: $e");
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
      showError(context, "Kunde inte ändra status: $e");
    }
  }

  void deleteTask(int index) async {
    try {
      await deleteTodoApi(todoList[index].id);
      setState(() => todoList.removeAt(index));
    } catch (e) {
      showError(context, "Kunde inte ta bort: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          // liten indikator för API-key status
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                apiKey == null ? "Ingen API key" : "Key OK",
                style: const TextStyle(fontSize: 14),
              ),
            ),
          )
        ],
      ),
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

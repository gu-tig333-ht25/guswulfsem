import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

getTodoDetails() async {
  const url = "https://todoapp-api.apps.k8s.gu.se/todos?key=4a3751fa-fbdb-4058-8f31-3a5824d7a82c";
  try {
    http.Response res = await http.get(Uri.parse(url));
    print(res.body);
  } catch (err){
    print(err.toString());
  }
}

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

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Todo App by Guiswulfsem",
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

List<Map<String, dynamic>> todoList = [];
final TextEditingController taskController = TextEditingController();
int updateIndex = -1;

class _MyHomePageState extends State<MyHomePage> {
  void deleteItem(int index) {
    setState(() {
      todoList.removeAt(index);
    });
  }

  void addList(String task) {
    setState(() {
      todoList.add({"title": task, "done": false});
      taskController.clear();
    });
  }

  // update task
  void updateListItem(String task, int index) {
    setState(() {
      todoList[index]["title"] = task;
      updateIndex = -1;
      taskController.clear();
    });
  }

  // toggle done/undone
  void markDone(int index) {
    setState(() {
      todoList[index]["done"] = !todoList[index]["done"];
    });
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
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
                      addList(taskController.text);
                    } else {
                      updateListItem(taskController.text, updateIndex);
                    }
                  }
                },
                child: Text(updateIndex == -1 ? "Add" : "Update"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // tasks list
          Expanded(
            child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    title: Text(
                      todoList[index]["title"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        decoration: todoList[index]["done"]
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            todoList[index]["done"]
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: Colors.green,
                          ),
                          onPressed: () => markDone(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              taskController.text = todoList[index]["title"];
                              updateIndex = index;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(index),
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
}}
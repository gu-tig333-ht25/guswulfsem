import 'package:flutter/material.dart';

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
      home: const MyHomePage(title: "Todo App by Guiswulfsem"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// global variables
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
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // input field + button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Enter task',
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
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: Colors.green,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 80,
                          child: Text(
                            todoList[index]["title"],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              decoration: todoList[index]["done"]
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            markDone(index);
                          },
                          icon: Icon(
                            todoList[index]["done"]
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              taskController.text = todoList[index]["title"];
                              updateIndex = index;
                            });
                          },
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () {
                            deleteItem(index);
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 25,
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

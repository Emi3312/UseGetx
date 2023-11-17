import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Todo List App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TodoListPage(),
    );
  }
}

class Todo {
  String title;
  bool completed;
  DateTime createdDate;

  Todo({required this.title, this.completed = false, DateTime? createdDate})
      : this.createdDate = createdDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'title': title,
        'completed': completed,
        'createdDate': createdDate.toIso8601String(),
      };

  factory Todo.fromJson(Map<String, dynamic> json) => Todo(
        title: json['title'],
        completed: json['completed'],
        createdDate: DateTime.parse(json['createdDate']),
      );
}

class TodoController extends GetxController {
  var todos = <Todo>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadTodos();
  }

  void addTask(Todo task) {
    todos.add(task);
    saveTodos();
  }

  void deleteTask(int index) {
    todos.removeAt(index);
    saveTodos();
  }

  void toggleTask(int index) {
    var oldTask = todos[index];
    var newTask = Todo(
        title: oldTask.title,
        completed: !oldTask.completed,
        createdDate: oldTask.createdDate);
    todos[index] = newTask;
    saveTodos();
    update(); 
  }

  void saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> stringList = todos.map((e) => jsonEncode(e.toJson())).toList();
    prefs.setStringList('todos', stringList);
  }

  void loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? stringList = prefs.getStringList('todos');
    if (stringList != null) {
      todos.assignAll(
          stringList.map((e) => Todo.fromJson(jsonDecode(e))).toList());
    }
  }
}

class TodoListPage extends StatelessWidget {
  final TodoController todoController = Get.put(TodoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo List GETX'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Obx(() => ListView.builder(
            itemCount: todoController.todos.length,
            itemBuilder: (context, index) {
              var todo = todoController.todos[index];
              return Dismissible(
                key: Key(todo.title),
                onDismissed: (_) => todoController.deleteTask(index),
                background: Container(color: Colors.red),
                child: Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  elevation: 4,
                  child: ListTile(
                    title: Text(todo.title,
                        style: TextStyle(
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : null)),
                    trailing: IconButton(
                      icon: Icon(
                        todo.completed
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: todo.completed ? Colors.green : Colors.grey,
                      ),
                      onPressed: () => todoController.toggleTask(index),
                    ),
                    onTap: () => todoController.toggleTask(index),
                  ),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => showDialogToAddTask(context),
      ),
    );
  }

  void showDialogToAddTask(BuildContext context) async {
    TextEditingController taskController = TextEditingController();

    String? task = await Get.dialog<String>(
      Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                12.0)), 
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nueva Tarea',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold), 
              ),
              SizedBox(height: 15),
              TextField(
                controller: taskController,
                decoration: InputDecoration(
                    hintText: "Nombre de la tarea",
                    border:
                        OutlineInputBorder(), 
                    prefixIcon: Icon(Icons.task) 
                    ),
                onSubmitted: (value) => Get.back(result: value),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment
                    .spaceEvenly, 
                children: [
                  ElevatedButton(
                    child: Text('Cancelar'),
                    onPressed: () => Get.back(result: null),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.redAccent, 
                    ),
                  ),
                  ElevatedButton(
                    child: Text('Añadir'),
                    onPressed: () {
                      if (taskController.text.isNotEmpty) {
                        Get.back(result: taskController.text);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green, 
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (task != null && task.isNotEmpty) {
      todoController.addTask(Todo(title: task));
    }
  }
}

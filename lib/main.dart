import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

final dio = Dio();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App (Flutter)',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text("Todo App (Flutter)"),
        ),
        body: HomeLayout(),
      ),
    );
  }
}

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayout();
}

class _HomeLayout extends State<HomeLayout> {
  final String _url = 'https://mobile-s11.iecmu.com';

  List<TodoData> _todos = [
    // TodoData(id: "1", todoText: "Task 1"),
    // TodoData(id: "2", todoText: "Task 2"),
    // TodoData(id: "3", todoText: "Task 3"),
  ];
  TodoData? currentTodo;
  bool editMode = false;

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
    });
  }

  void setCurrentTodo(TodoData todo) {
    setState(() {
      currentTodo = todo;
    });
  }

  void resetState() {
    setState(() {
      currentTodo = null;
      editMode = false;
    });
  }

  Future<void> getTodo() async {
    try {
      final res = await dio.get<List<dynamic>>("$_url/todo");
      final data = res.data ?? [];
      final todos = data.map((item) {
        final map = Map<String, dynamic>.from(item);
        return TodoData.fromJson(map);
      }).toList();
      todos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (!mounted) return;
      setState(() {
        _todos = todos;
      });
    } catch (e, stackTrace) {
      debugPrint('Unexpected error loading todos: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while loading todos.'),
        ),
      );
    }
  }

  Future<void> createTodo(String todoText) async {
    try {
      final Map<String, dynamic> payload = {
        "todoText": todoText,
      };
      await dio.put("$_url/todo", data: payload);
      await getTodo();
    } catch (e, stackTrace) {
      debugPrint('Unexpected error creating todo: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while creating the todo.'),
        ),
      );
    }
  }

  Future<void> deleteTodo(String id) async {
    try {
      final Map<String, dynamic> payload = {
        "id": id,
      };
      await dio.delete("$_url/todo", data: payload);
      await getTodo();
    } catch (e, stackTrace) {
      debugPrint('Unexpected error deleting todo: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while deleting the todo.'),
        ),
      );
    }
  }

  Future<void> updateTodo({
    required String id,
    required String todoText,
  }) async {
    try {
      final Map<String, dynamic> payload = {
        "id": id,
        "todoText": todoText,
      };
      await dio.patch("$_url/todo", data: payload);
      await getTodo();
    } catch (e, stackTrace) {
      debugPrint('Unexpected error updating todo: $e\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong while updating the todo.'),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getTodo();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        spacing: 10.0,
        children: [
          TodoForm(
            createTodo: createTodo,
            currentTodo: currentTodo,
            editMode: editMode,
            resetState: resetState,
            updateTodo: updateTodo,
          ),
          TodoDisplay(
            todos: _todos,
            deleteTodo: deleteTodo,
            setCurrentTodo: setCurrentTodo,
            toggleEditMode: toggleEditMode,
            editMode: editMode,
          ),
        ],
      ),
    );
  }
}

class TodoForm extends StatefulWidget {
  const TodoForm({
    super.key,
    required this.createTodo,
    required this.currentTodo,
    required this.editMode,
    required this.updateTodo,
    required this.resetState,
  });
  final Future<void> Function(String todoText) createTodo;
  final Future<void> Function({required String id, required String todoText})
  updateTodo;
  final void Function() resetState;
  final TodoData? currentTodo;
  final bool editMode;

  @override
  State<TodoForm> createState() => _TodoForm();
}

class _TodoForm extends State<TodoForm> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: "");
  }

  @override
  void didUpdateWidget(covariant TodoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentTodo != oldWidget.currentTodo) {
      _controller.text = widget.currentTodo?.todoText ?? "";
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        spacing: 10.0,
        children: [
          TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: "Todo Text",
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10.0,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final todoText = _controller.text;
                  if (todoText.trim().isEmpty) return;
                  if (!widget.editMode) {
                    await widget.createTodo(todoText);
                  } else {
                    if (widget.currentTodo == null) return;
                    await widget.updateTodo(
                      id: widget.currentTodo?.id ?? "",
                      todoText: todoText,
                    );
                  }
                  if (!mounted) return;
                  _controller.clear();
                  widget.resetState();
                },
                child: Text(!widget.editMode ? "Create" : "Edit"),
              ),
              if (widget.editMode)
                ElevatedButton(
                  onPressed: () {
                    if (!mounted) return;
                    _controller.clear();
                    widget.resetState();
                  },
                  child: Text("Cancel"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class TodoDisplay extends StatelessWidget {
  const TodoDisplay({
    super.key,
    required this.todos,
    required this.deleteTodo,
    required this.setCurrentTodo,
    required this.toggleEditMode,
    required this.editMode,
  });

  final Future<void> Function(String id) deleteTodo;
  final void Function(TodoData todo) setCurrentTodo;
  final bool editMode;
  final List<TodoData> todos;
  final void Function() toggleEditMode;

  String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 10.0),
        child: ListView(
          children: todos
              .map(
                (todo) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 10.0,
                  children: [
                    Row(
                      spacing: 10.0,
                      children: [
                        Text(
                          truncateText(todo.todoText, 10),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 0.0,
                      children: [
                        Text(
                          DateFormat('d-MMM-yy (H:mm)').format(todo.updatedAt),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),

                          color: editMode ? Colors.grey : Colors.blue,
                          tooltip: "Edit",
                          onPressed: editMode
                              ? null
                              : () {
                                  setCurrentTodo(todo);
                                  toggleEditMode();
                                },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: editMode ? Colors.grey : Colors.blue,
                          tooltip: "Delete",
                          onPressed: editMode
                              ? null
                              : () {
                                  deleteTodo(todo.id);
                                },
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class TodoData {
  TodoData({
    required this.id,
    required this.todoText,
    this.isDone = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory TodoData.fromJson(Map<String, dynamic> json) {
    return TodoData(
      id: json["id"] as String,
      todoText: json["todoText"] as String,
      isDone: json["isDone"] as bool? ?? false,
      createdAt: json["createdAt"] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
  final String id;
  final String todoText;
  final bool isDone;
  final DateTime createdAt;
  final DateTime updatedAt;
}

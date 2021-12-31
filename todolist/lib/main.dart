import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application name
      title: 'Flutter Hello World - To Do App',
      // Application theme data, you can set the colors for the application as
      // you want
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // A widget which will be started on application startup
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String title;
  TextEditingController todo_text_controller = TextEditingController();
  final LocalStorage storage = LocalStorage('todo_app');
  List<TodoItem> todos;
  bool initialized = false;
  Future loadStorage;
  int numBlocked;
  FocusNode myFocusNode;
  @override
  void initState() {
    super.initState();
    loadStorage = storage.ready;
    todos = [];
    numBlocked = 0;
    for (var todo in todos) {
      if (todo.isChecked == true) {
        numBlocked++;
      }
    }
    myFocusNode = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // The title text which will be shown on the action bar
        title: Text("Todo App "),
      ),
      body: FutureBuilder(
          future: loadStorage,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasData) {
              if (!initialized) {
                var items = storage.getItem('todos');
                if (items == null) {
                  storage.setItem('todos', []);
                } else {
                  todos = [];
                  for (var item in items) {
                    todos.add(TodoItem(todoText: item['todoText'], isChecked: item['isChecked']));
                  }
                  for (var todo in todos) {
                    if (todo.isChecked == true) {
                      numBlocked++;
                    }
                  }
                }
                initialized = true;
              }
              return Center(
                child: Column(children: [
                  Flexible(
                      fit: FlexFit.loose,
                      child: ListView.builder(
                          itemCount: todos.length,
                          itemBuilder: (context, index) {
                            return SingleTodo(
                              todos: todos,
                              index: index,
                              storage: storage,
                              checkMarked: (value) {
                                todos[index].isChecked = !todos[index].isChecked;
                                saveToStorage();
                                if (value == true) {
                                  numBlocked++;
                                } else {
                                  numBlocked--;
                                }
                                setState(() {});
                              },
                            );
                          })),
                  Row(mainAxisSize: MainAxisSize.max, children: [
                    Expanded(
                      child: TextFormField(
                        controller: todo_text_controller,
                        focusNode: myFocusNode,
                        onFieldSubmitted: (value) {
                          if (todo_text_controller.text.trim() != "") {
                            todos.add(TodoItem(todoText: todo_text_controller.text, isChecked: false));
                            todo_text_controller.clear();
                            saveToStorage();
                            myFocusNode.requestFocus();
                            setState(() {});
                            myFocusNode.requestFocus();
                            setState(() {});
                          }
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                        child: Text("ADD"),
                        onPressed: todo_text_controller.text.trim().length < 1
                            ? null
                            : () {
                                if (todo_text_controller.text.trim() != "") {
                                  todos.add(TodoItem(todoText: todo_text_controller.text, isChecked: false));
                                  todo_text_controller.clear();
                                  saveToStorage();
                                  setState(() {});
                                }
                              }),
                    SizedBox(width: 10),
                    ElevatedButton(
                        child: Text("DELETE"),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red,
                        ),
                        onPressed: numBlocked < 1
                            ? null
                            : () {
                                todos.removeWhere((todo) => todo.isChecked == true);
                                saveToStorage();
                                numBlocked = 0;
                                setState(() {});
                              })
                  ])
                ]),
              );
            } else {
              return Center(child: Text("An error occurred."));
            }
          }),
    );
  }

  saveToStorage() {
    List<Map<String, dynamic>> toSave = [];
    for (var todo in todos) {
      toSave.add(todo.my_toJSON());
    }
    storage.setItem('todos', toSave);
  }
}

class TodoItem {
  String todoText;
  bool isChecked;
  TodoItem({this.todoText, this.isChecked});

  Map<String, dynamic> my_toJSON() {
    Map<String, dynamic> m = Map();
    m['todoText'] = todoText;
    m['isChecked'] = isChecked;
    return m;
  }
}

class SingleTodo extends StatefulWidget {
  List<TodoItem> todos;
  int index;
  LocalStorage storage;
  Function checkMarked;
  SingleTodo({this.todos, this.index, this.storage, this.checkMarked});
  @override
  _SingleTodoState createState() => _SingleTodoState();
}

class _SingleTodoState extends State<SingleTodo> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(widget.todos[widget.index].todoText, style: widget.todos[widget.index].isChecked ? TextStyle(decoration: TextDecoration.lineThrough) : TextStyle()),
        trailing: Checkbox(
          checkColor: Colors.white,
          value: widget.todos[widget.index].isChecked,
          onChanged: widget.checkMarked,
        ));
  }

  saveToStorage() {
    List<Map<String, dynamic>> toSave = [];
    for (var todo in widget.todos) {
      toSave.add(todo.my_toJSON());
    }
    widget.storage.setItem('todos', toSave);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_model.dart';

class TodoService {
  final _supabase = Supabase.instance.client;

  // সব todo fetch করো
  Future<List<Todo>> fetchTodos() async {
    final response = await _supabase
        .from('todos')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((e) => Todo.fromJson(e)).toList();
  }

  // নতুন todo add করো
  Future<void> addTodo(String title, String? description) async {
    await _supabase.from('todos').insert({
      'title': title,
      'description': description,
      'is_completed': false,
    });
  }

  // todo update করো
  Future<void> updateTodo(String id, String title, String? description) async {
    await _supabase.from('todos').update({
      'title': title,
      'description': description,
    }).eq('id', id);
  }

  // complete/incomplete toggle করো
  Future<void> toggleComplete(String id, bool current) async {
    await _supabase
        .from('todos')
        .update({'is_completed': !current}).eq('id', id);
  }

  // todo delete করো
  Future<void> deleteTodo(String id) async {
    await _supabase.from('todos').delete().eq('id', id);
  }
}
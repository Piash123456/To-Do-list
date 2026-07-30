import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/todo_model.dart';
import '../services/todo_service.dart';
import 'add_edit_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TodoService _service = TodoService();
  List<Todo> _todos = [];
  bool _isLoading = true;

  // Premium Theme Colors
  static const Color primaryDark = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFFA855F7); // Purple
  static const Color bg = Color(0xFFF1F5F9); // Light BG
  static const Color card = Colors.white;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() => _isLoading = true);
    try {
      final todos = await _service.fetchTodos();
      setState(() => _todos = todos);
    } catch (e) {
      _showSnack('Error loading tasks', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleComplete(Todo todo) async {
    HapticFeedback.lightImpact(); 
    await _service.toggleComplete(todo.id, todo.isCompleted);
    await _loadTodos();
  }

  Future<void> _deleteTodo(String id) async {
    HapticFeedback.mediumImpact();
    await _service.deleteTodo(id);
    _showSnack('Task deleted 🗑️');
    await _loadTodos();
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _openAddEdit({Todo? todo}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditScreen(todo: todo)),
    );
    if (result == true) {
      await _loadTodos();
      _showSnack(todo == null ? 'Task Added! ✨' : 'Task Updated! 📝');
    }
  }

  int get _completedCount => _todos.where((t) => t.isCompleted).length;

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final userName = currentUser?.userMetadata?['name'] ?? 'Awesome User';
    final firstName = userName.trim().isNotEmpty ? userName.trim().split(' ')[0] : 'User';
    final initialLetter = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    final progress = _todos.isEmpty ? 0.0 : _completedCount / _todos.length;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM').format(DateTime.now()),
                        style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getGreeting()}, $firstName',
                        style: GoogleFonts.poppins(color: const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                      setState(() {}); 
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryDark.withOpacity(0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: primaryDark.withOpacity(0.1),
                        child: Text(
                          initialLetter,
                          style: GoogleFonts.poppins(color: primaryDark, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [primaryDark, primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Goal',
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: primaryDark))
                  : _todos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.rocket_launch_rounded, 
                                  size: 70,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'A Fresh Start! 🌟',
                                style: GoogleFonts.poppins(
                                  fontSize: 22, 
                                  fontWeight: FontWeight.bold, 
                                  color: const Color(0xFF1E293B)
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Your day is a blank canvas. Tap the + button to add your first task and start organizing.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade600, 
                                    fontSize: 14, 
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40), 
                            ],
                          ),
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100), 
                          itemCount: _todos.length,
                          itemBuilder: (context, index) => _buildTodoCard(_todos[index]),
                        ),
            ),
          ],
        ),
      ),

      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [primaryDark, primaryLight]),
          boxShadow: [
            BoxShadow(color: primaryDark.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _openAddEdit(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
          label: Text('New Task', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // কার্ডের মাঝখানের গ্যাপ একটু কমানো হয়েছে
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.45,
          children: [
            SlidableAction(
              onPressed: (_) => _openAddEdit(todo: todo),
              backgroundColor: const Color(0xFF38BDF8),
              foregroundColor: Colors.white,
              icon: Icons.edit_rounded,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            ),
            SlidableAction(
              onPressed: (_) => _deleteTodo(todo.id),
              backgroundColor: const Color(0xFFFB7185),
              foregroundColor: Colors.white,
              icon: Icons.delete_rounded,
              borderRadius: const BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20), 
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
            ],
          ),
          child: Padding(
            // কার্ডের ভেতরের প্যাডিং কমিয়ে বক্স চিকন করা হয়েছে
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // সব কিছু লম্বালম্বি মাঝখানে থাকবে
              children: [
                // ১. চেকবক্স
                GestureDetector(
                  onTap: () => _toggleComplete(todo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: todo.isCompleted ? primaryDark : Colors.transparent,
                      border: Border.all(
                        color: todo.isCompleted ? Colors.transparent : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: todo.isCompleted ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                  ),
                ),
                const SizedBox(width: 14),
                
                // ২. টাস্কের টাইটেল এবং ডেসক্রিপশন
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        todo.title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: todo.isCompleted ? Colors.grey.shade400 : const Color(0xFF1E293B),
                          decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                      if (todo.description != null && todo.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          todo.description!,
                          maxLines: 1, // ডেসক্রিপশন বেশি বড় হলে ১ লাইনেই দেখাবে
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),

                // ৩. ডানপাশে Date & Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(todo.createdAt.toLocal()), // সময়
                      style: GoogleFonts.poppins(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: todo.isCompleted ? Colors.grey.shade400 : primaryDark
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d').format(todo.createdAt.toLocal()), // তারিখ
                      style: GoogleFonts.poppins(
                        fontSize: 11, 
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
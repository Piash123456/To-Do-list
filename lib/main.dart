import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart'; // লগইন স্ক্রিন ইমপোর্ট করা হলো

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(), // এখানে সরাসরি HomeScreen না দিয়ে AuthGate দেওয়া হলো
    );
  }
}

// এই ক্লাসটি পাহারাদারের মতো কাজ করবে
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      // ইউজারের লগইন অবস্থা শুনবে
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // সেশন (Session) চেক করা হচ্ছে
        final session = snapshot.hasData ? snapshot.data!.session : null;

        // যদি সেশন থাকে (লগইন করা), তবে HomeScreen-এ পাঠাও
        if (session != null) {
          return const HomeScreen();
        }

        // সেশন না থাকলে (লগআউট), LoginScreen-এ পাঠাও
        return const LoginScreen();
      },
    );
  }
}
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ১. বর্তমানে লগইন করা ইউজারকে চেক করার জন্য
  User? get currentUser => _supabase.auth.currentUser;

  // ২. ইমেইল, পাসওয়ার্ড এবং নাম দিয়ে অ্যাকাউন্ট তৈরি (Register)
  Future<void> signUp({required String email, required String password, required String name}) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // ইউজারের নাম এখানে সেভ হবে
    );
  }

  // ৩. ইমেইল ও পাসওয়ার্ড দিয়ে লগইন (Login)
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ৪. অ্যাকাউন্ট থেকে বের হওয়া (Logout)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // ৫. ইউজার লগইন নাকি লগআউট অবস্থায় আছে তা শোনার জন্য (Stream)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// পেজের ৩টি স্টেপ ট্র্যাক করার জন্য
enum ResetStep { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  ResetStep _currentStep = ResetStep.email;
  
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

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

  // স্টেপ ১: মেইলে OTP পাঠানো
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showSnack('Please enter your email', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        _showSnack('6-digit OTP sent to your email! ✉️');
        // মেইল পাঠানোর পর অটোমেটিক UI চেঞ্জ হয়ে OTP স্টেপে চলে যাবে
        setState(() => _currentStep = ResetStep.otp); 
      }
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // স্টেপ ২: OTP ভেরিফাই করা
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      _showSnack('Please enter a valid 6-digit OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailCtrl.text.trim(),
        token: otp,
        type: OtpType.recovery,
      );
      if (mounted) {
        _showSnack('OTP Verified! Enter new password. 🔓');
        // OTP মিললে অটোমেটিক UI চেঞ্জ হয়ে New Password স্টেপে যাবে
        setState(() => _currentStep = ResetStep.newPassword); 
      }
    } catch (e) {
      _showSnack('Invalid OTP. Please check again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // স্টেপ ৩: নতুন পাসওয়ার্ড সেভ করা
  Future<void> _updatePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    if (newPass.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        _showSnack('Password updated successfully! 🎉');
        Navigator.pop(context); // কাজ শেষ, লগইন পেজে ব্যাক করবে
      }
    } catch (e) {
      _showSnack('Failed to update password: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Forgot Password?';
    String subtitle = 'Enter your email to receive a reset code.';
    if (_currentStep == ResetStep.otp) {
      title = 'Enter OTP';
      subtitle = 'We have sent a 6-digit code to your email.';
    } else if (_currentStep == ResetStep.newPassword) {
      title = 'New Password';
      subtitle = 'Create a strong new password.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E293B),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentStep == ResetStep.newPassword ? Icons.lock_person_rounded : Icons.mark_email_read_rounded,
                  size: 80,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 32),
              
              Text(title, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(height: 12),
              Text(subtitle, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 40),
              
              // ডায়নামিক ইনপুট ফিল্ড (স্টেপ অনুযায়ী অটোমেটিক বক্স বদলাবে)
              if (_currentStep == ResetStep.email) ...[
                _buildCustomTextField(controller: _emailCtrl, label: 'Email Address', icon: Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              ] else if (_currentStep == ResetStep.otp) ...[
                _buildCustomTextField(controller: _otpCtrl, label: '6-Digit OTP', icon: Icons.pin_rounded, keyboardType: TextInputType.number),
              ] else if (_currentStep == ResetStep.newPassword) ...[
                _buildCustomTextField(controller: _newPasswordCtrl, label: 'New Password', icon: Icons.lock_rounded, isPassword: true),
              ],
              
              const SizedBox(height: 32),
              
              // ডায়নামিক বাটন (স্টেপ অনুযায়ী বাটন চেঞ্জ হবে)
              Container(
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
                  boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : () {
                          if (_currentStep == ResetStep.email) _sendOtp();
                          else if (_currentStep == ResetStep.otp) _verifyOtp();
                          else _updatePassword();
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          _currentStep == ResetStep.email ? 'Send Code' : _currentStep == ResetStep.otp ? 'Verify Code' : 'Save Password',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({required TextEditingController controller, required String label, required IconData icon, bool isPassword = false, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? _obscurePassword : false,
        style: GoogleFonts.poppins(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 22),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.grey.shade400, size: 22), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
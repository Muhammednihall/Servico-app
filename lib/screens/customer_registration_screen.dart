import 'package:flutter/material.dart';
import 'login_screen.dart';

class CustomerRegistrationScreen extends StatefulWidget {
  const CustomerRegistrationScreen({super.key});

  @override
  State<CustomerRegistrationScreen> createState() => _CustomerRegistrationScreenState();
}

class _CustomerRegistrationScreenState extends State<CustomerRegistrationScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final Color _primaryColor = const Color(0xFF2463eb);
  final Color _backgroundLight = const Color(0xFFf8f9fc);
  final Color _inputBorder = const Color(0xFFd0d7e7);
  final Color _textMain = const Color(0xFF0e121b);
  final Color _textSecondary = const Color(0xFF4d6599);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildForm(),
              _buildLoginLink(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          IconButton(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFf1f3f7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: Color(0xFF0e121b),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          const Text(
            'Customer Registration',
            style: TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with the best AI-powered city services.',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      child: Column(
        children: [
          _buildTextField(
            label: 'Full Name',
            hint: 'Enter your full name',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: 'Email Address',
            hint: 'name@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildPasswordField(),
          const SizedBox(height: 20),
          _buildConfirmPasswordField(),
          const SizedBox(height: 16),
          _buildRegisterButton(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _inputBorder,
              width: 1,
            ),
          ),
          child: TextField(
            style: const TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 16,
            ),
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSecondary,
                fontSize: 16,
              ),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: _textSecondary,
                      size: 20,
                    )
                  : null,
              suffixIcon: icon == Icons.person_outline
                  ? Icon(
                      Icons.person_outline,
                      color: _textSecondary,
                      size: 20,
                    )
                  : icon == Icons.mail_outline
                      ? Icon(
                          Icons.mail_outline,
                          color: _textSecondary,
                          size: 20,
                        )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Password',
            style: TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _inputBorder,
              width: 1,
            ),
          ),
          child: TextField(
            obscureText: !_isPasswordVisible,
            style: const TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Create a password',
              hintStyle: TextStyle(
                color: _textSecondary,
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Confirm Password',
            style: TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _inputBorder,
              width: 1,
            ),
          ),
          child: TextField(
            obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(
              color: Color(0xFF0e121b),
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Confirm your password',
              hintStyle: TextStyle(
                color: _textSecondary,
                fontSize: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: _textSecondary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Implement customer registration logic
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: _primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Register',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Text(
              'Login Here',
              style: TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

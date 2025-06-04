import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_uas/api/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _storage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password harus diisi.', isError: true);
      return;
    }
    if (!email.contains('@')) {
      _showSnackBar('Format email tidak valid.', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final String apiUrl = '${ApiConfig.baseUrl}/login';
    print("Attempting login to: $apiUrl");

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return; // Cek mounted setelah await

      final responseData = jsonDecode(response.body);
      print("Login Response Status: ${response.statusCode}");
      print("Login Response Body: $responseData");

      if (response.statusCode == 200) {
        String? token = responseData['token'] as String?;
        String? username = responseData['username'] as String? ??
            responseData['data']?['username'] as String? ??
            responseData['user']?['username'] as String?;

        if (token != null && token.isNotEmpty) {
          await _storage.write(key: 'authToken', value: token);
          print('Token berhasil disimpan: $token');

          if (username != null && username.isNotEmpty) {
            await _storage.write(key: 'loggedInUsername', value: username);
            print('Username berhasil disimpan: $username');
          } else {
            print('Username tidak ditemukan dalam respons login.');
          }

          _showSnackBar(responseData['message'] ?? 'Login berhasil!');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          print('Token tidak ditemukan dalam respons login.');
          _showSnackBar('Login berhasil tetapi token tidak diterima.',
              isError: true);
        }
      } else {
        _showSnackBar(
            responseData['message']?.toString() ??
                'Login gagal. Periksa kembali email dan password Anda.',
            isError: true);
      }
    } catch (e) {
      print('Error during login: $e');
      if (mounted) {
        _showSnackBar(
            'Tidak dapat terhubung ke server. Periksa koneksi Anda dan konfigurasi URL API.',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/photo-signin.png', // pastikan gambar ada di folder assets dan terdaftar di pubspec.yaml
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                  color: Colors.grey[800],
                  child: const Center(
                      child: Text('Gagal memuat gambar background',
                          style: TextStyle(color: Colors.white))));
            },
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Use proper credentials to continue',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _loginUser,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2.0,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don’t have an account?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushNamed(context,
                                  '/register'); // ganti ke halaman register
                            },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Colors.lightGreenAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white54),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          // Tambahkan style untuk focused border
          borderSide: const BorderSide(color: Colors.amber),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (_emailController.text != 'admin@mail.com' ||
        _passwordController.text != '12345') {
      setState(() => _error = 'Email atau kata sandi salah. Coba cek lagi.');
      return;
    }
    setState(() => _error = null);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.eco, color: Colors.white, size: 30),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'Selamat datang',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Masuk untuk melihat kondisi kebunmu',
                    style: TextStyle(color: context.muted),
                  ),
                  SizedBox(height: 32),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline),
                      enabledBorder: hasError
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppColors.danger),
                            )
                          : null,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Kata sandi',
                      prefixIcon: Icon(Icons.lock_outline),
                      enabledBorder: hasError
                          ? OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: AppColors.danger),
                            )
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: EdgeInsets.only(top: 10, left: 4),
                      child: Text(
                        _error!,
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 13),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Routing ke form lupa kata sandi
                      },
                      child: Text('Lupa kata sandi?'),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(onPressed: _login, child: Text('Masuk')),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun?',
                          style: TextStyle(color: context.muted)),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => RegisterPage()),
                        ),
                        child: Text('Daftar di sini'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

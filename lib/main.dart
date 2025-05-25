import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_b3/universPage.dart';
import 'SignUp.dart';
import 'package:projet_b3/config.dart' as config;
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LogInPage(title: 'Page de connexion'),
    );
  }
}





class LogInPage extends StatefulWidget {
  const LogInPage({super.key, required this.title});

  final String title;

  @override
  State<LogInPage> createState() => _LogInState();
}

class _LogInState extends State<LogInPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void _login() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(config.apiUrl + '/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['token'];
        final userId = 61;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token); // Stocke le token
        await prefs.setInt('userId', userId); // Stocke l'userId


// Vérifie que l'ID est bien un int
        print("Réponse brute: ${response.body}");



        // Rediriger vers la page Univers
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const UniversPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/monimage.png'),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: Container()),
              Container(
                height: MediaQuery.of(context).size.height * 0.70,
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(100),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA925),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildTextField('username', usernameController),
                        const SizedBox(height: 16),
                        _buildTextField('Mot de passe', passwordController, obscure: true),
                        const SizedBox(height: 8),
                        const Text(
                          "Mot de passe oublié ?",
                          style: TextStyle(color: Color(0xFFFFA925)),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _buildLoginButton(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Pas de compte ? "),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                                );
                              },
                              child: const Text(
                                "Créer un compte",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFA925),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscure = false}) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA925), Color(0xFFFF7841)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(2),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none,
          ),
          labelText: label,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const StadiumBorder(),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
      ),
      onPressed: _login,
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA925), Color(0xFFFF7841)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 50),
          child: const Text(
            "Se connecter",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_b3/characterPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/CardUnivers.dart';
import 'package:projet_b3/config.dart' as config;


class UniversPage extends StatefulWidget {
  const UniversPage({super.key});

  @override
  State<UniversPage> createState() => _UniversPageState();
}

class _UniversPageState extends State<UniversPage> {
  List<dynamic> universList = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchUnivers();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }


  Future<void> fetchUnivers() async {
    try {
      // Récupérer le token depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Si le token est présent, l'ajouter aux headers de la requête
      final response = await http.get(
        Uri.parse(config.apiUrl + '/universes'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          universList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }



  void _showCreateUniversDialog() async {
    final TextEditingController nameController = TextEditingController();

    // Récupérer le token depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Créer un univers"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "Nom de l'univers",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  try {
                    final response = await http.post(
                      Uri.parse(config.apiUrl + '/universes'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({'name': name}),
                    );

                    if (response.statusCode == 201) {
                      Navigator.of(context).pop();
                      fetchUnivers();

                      // ✅ SnackBar de succès
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Univers créé avec succès 🎉'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // ❌ SnackBar d'erreur serveur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Erreur lors de la création de l'univers."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    // ❌ SnackBar d'erreur réseau
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Une erreur est survenue. Vérifie ta connexion."),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text("Créer"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateUniversDialog,
        backgroundColor: const Color(0xFFFFA925),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFA925), Color(0xFFFF7841)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(Icons.menu, size: 40, color: Colors.white),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFFA925), Color(0xFFFF7841)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Icon(Icons.search, size: 30, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                  ? const Center(child: Text("Erreur lors du chargement"))
                  : ListView.builder(
                itemCount: universList.length,
                itemBuilder: (context, index) {
                  final item = universList[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CharacterPage(universeId: item["id"].toString()),
                        ),
                      );
                    },
                    child: MonWidget(
                      imagePath: 'https://yodai.wevox.cloud/image_data/${item["image"]}',
                      title: item['name'],

                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

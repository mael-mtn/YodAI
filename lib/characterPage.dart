import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet_b3/chatPage.dart';
import 'package:projet_b3/config.dart' as config;
import 'package:shared_preferences/shared_preferences.dart';


class CharacterPage extends StatefulWidget {
  const CharacterPage({super.key, required this.universeId});
  final String universeId;

  @override
  State<CharacterPage> createState() => _CharacterPageState();
}

class _CharacterPageState extends State<CharacterPage> {
  List<dynamic> charactersList = [];
  bool isLoading = true;
  bool hasError = false;

  get character => null;



  @override
  void initState() {
    super.initState();
    fetchCharacters();
  }


  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }





  Future<void> fetchCharacters() async {
    try {
      // Récupérer le token depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final userId = prefs.getInt('userId');
      print("Utilisateur connecté avec ID : $userId");



      // Si le token est présent, l'ajouter aux headers de la requête
      final response = await http.get(
        Uri.parse('${config.apiUrl}/universes/${widget.universeId}/characters'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          charactersList = json.decode(response.body);
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


  Future<int?> getOrCreateConversation(int characterId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final userId = prefs.getInt('userId');

    if (token == null || userId == null) {
      print("Token ou user_id manquant");
      return null;
    }

    // 🔎 Étape 1 : chercher une conversation existante
    final response = await http.get(
      Uri.parse('${config.apiUrl}/conversations'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);

      final existing = data.firstWhere(
            (conv) => conv['character_id'] == characterId && conv['user_id'] == userId,
        orElse: () => null,
      );

      if (existing != null) {
        return existing['id']; // ✅ Conversation déjà existante
      }
    }

    // ✳️ Étape 2 : créer une nouvelle conversation
    final createResponse = await http.post(
      Uri.parse('${config.apiUrl}/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'character_id': characterId,
        'user_id': userId,
      }),
    );

    if (createResponse.statusCode == 201) {
      final data = json.decode(createResponse.body);
      return data['conversationId'];
    } else {
      print("Erreur création conversation : ${createResponse.statusCode}");
      print("Réponse : ${createResponse.body}");
      return null;
    }
  }


  void _showCreateCharecterDialog() async {
    final TextEditingController nameController = TextEditingController();

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
              labelText: "Nom du personnage",
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
                      Uri.parse('${config.apiUrl}universes/${widget.universeId}/characters'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer $token',
                      },
                      body: jsonEncode({'name': name}),
                    );

                    if (response.statusCode == 201) {
                      Navigator.of(context).pop();
                      fetchCharacters();

                      // ✅ SnackBar de succès
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Personnage créé avec succès 🎉'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // ❌ SnackBar d'erreur serveur
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Erreur lors de la création du personnage."),
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
        onPressed: _showCreateCharecterDialog,
        backgroundColor: const Color(0xFFFFA925),
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text("Liste des Personnages")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: charactersList.length,
        itemBuilder: (context, index) {
          final character = charactersList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () async {
                final characterId = character["id"];

                final conversationId = await getOrCreateConversation(characterId);

                if (conversationId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        characterId: character["id"],
                        characterName: character["name"],
                        conversationId: conversationId,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Impossible d'accéder à la conversation."),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(
                          'https://yodai.wevox.cloud/image_data/${character["image"]}',
                        ),
                        onBackgroundImageError: (_, __) {},
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          character["name"]!,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

        },

      ),
    );
  }
}

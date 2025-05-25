import 'package:flutter/material.dart';

class MonWidget extends StatelessWidget {
  final String imagePath;
  final String title;

  const MonWidget({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Padding extérieur
      child: Card(
        elevation: 8, // Augmentation de l'ombre pour un effet flottant
        shadowColor: Colors.black.withOpacity(0.3), // Ombre douce
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Coins arrondis
        ),
        child: Container(
          height: 100, // Hauteur de la carte augmentée
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                  bottom: Radius.circular(12), // Arrondi pour les deux côtés
                ),
                child: Image.network(
                  imagePath,
                  height: double.infinity,
                  width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis, // Gestion des longs textes
                    maxLines: 2, // Limite de 2 lignes pour le texte
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

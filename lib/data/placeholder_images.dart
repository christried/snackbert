class PlaceholderImages {
  static final List<String> _mealPlaceholderImage = [
    'assets/snackbert_mascot_shrug.png',
    'assets/snackbert_mascot_face.png',
    'assets/snackbert_mascot_face_shush.png',
    'assets/snackbert_mascot_face_think.png',
  ];

  static String getPlaceholderForSingleMeal(String id) {
    final index = id.hashCode % _mealPlaceholderImage.length;
    return _mealPlaceholderImage[index.abs()];
  }
}

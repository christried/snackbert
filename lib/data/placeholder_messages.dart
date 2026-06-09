import 'dart:math';

class PlaceholderMessages {
  static final List<String> _newEntryInfoBoxMessage = [
    "Gib Snackbert einfach ein Foto, eine Sprachi oder einen kurzen Text. Oder Alles.",
    "Füttere Snackbert mit Text, Foto oder Audio. Eins reicht, alles geht!",
    "Egal ob Foto, Text oder Sprachi: Ein Input reicht. Du kannst auch mischen!",
    "Foto, Audio oder Text? Such's dir aus. Du kannst auch alles kombinieren.",
    "Foto, Audio oder Text - eins reicht Snackbert völlig. Kombi geht natürlich!",
    "Ob Bild, Text oder eine kurze Sprachi - eins davon reicht Snackbert völlig!",
    "Foto, Audio oder Text reicht Snackbert völlig. Gerne auch im Doppelpack!",
    "Schnapp dir ein Foto, Text oder Audio. Eins reicht, mehr geht immer!",
    "Ein Input genügt: Foto, Text oder Sprachi. Kombiniere, wie du magst!",
    "Text, Bild oder Audio? Snackbert reicht eins. Du kannst auch alles nutzen!",
    "Gib Snackbert ein Foto, Audio oder Text. Eins reicht, Mix ist erlaubt!",
  ];

  static String get randomNewEntryInfoBoxMessage =>
      _newEntryInfoBoxMessage[Random().nextInt(_newEntryInfoBoxMessage.length)];

  static final List<String> _newEntryTextInputHint = [
    "z.B. 1 Beyond Burger, Pommes, etwas Ketchup [...]",
    "z.B. 150g Nudeln, Räuchertofu, veganes Pesto [...]",
    "z.B. 1 Seitan-Döner mit viel Knoblauchsoße [...]",
    "z.B. 6 vegane Nuggies, große Pommes, Mayo [...]",
    "z.B. 50g Haferflocken, Sojamilch, 1 Banane [...]",
    "z.B. 2 Wraps, Falafel, Hummus, etwas Salat [...]",
    "z.B. 200g Kichererbsen, Kokosmilch und Reis [...]",
    "z.B. 1 vegane Salami-Pizza, extra Schmelz [...]",
    "z.B. 100g Quinoa, 1 Avocado, süße Sojasoße [...]",
    "z.B. 2 Stück Kuchen, 1 Oat Latte [...]",
  ];

  static String get randomNewEntryTextInputHint =>
      _newEntryTextInputHint[Random().nextInt(_newEntryTextInputHint.length)];
}

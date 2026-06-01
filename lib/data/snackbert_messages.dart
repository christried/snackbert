import 'dart:math';

class SnackbertMessages {
  static final List<String> _greetings = [
    "Omg Hi, da bist du ja endlich! 🐿️",
    "Na, auch mal wieder da? Ich hab dir nichts weggegessen... versprochen! 🥜",
    "Du strahlst ja mehr als eine frisch polierte Haselnuss heute!",
    "Da ist mein Lieblingsmensch! Hast du Nüsse dabei? Nur Spaß... vielleicht.",
    "Snackbert meldet sich zum Dienst! Bereit, ein paar Sachen einzutragen?",
    "Wuschelige Grüße! Ich hab den Taschenrechner schon mal warmgelaufen.",
    "Pfoten hoch! Jetzt wird geloggt. Schön, dass du da bist!",
    "Mein Herz klopft schneller als meine Backen vollgestopft mit Vorräten!",
    "Hey! Gib mir ein High-Five, ich freu mich riesig, dich zu sehen!",
    "Zusammen schaffen wir das – ein Eintrag nach dem anderen. Los geht's!",
    "Endlich! Ich hab schon fast angefangen, meine Vorräte ohne dich zu zählen.",
  ];

  static final List<String> _errorFallbacks = [
    "Upsi... Ich hab wohl ein Kabel angeknabbert. Probierst du es nochmal? ⚡",
    "Irgendwie hat sich eine Haselnuss im Getriebe verfangen. Noch mal versuchen?",
    "Oh Schreck! Da ist mir glatt die Eichel aus den Pfoten gefallen. Fehler!",
    "Menno! Der Knopf mag meine flauschigen Pfoten gerade nicht.",
    "Meine Backen sind voll, aber die Server-Verbindung ist leer. Ein Fehler!",
    "Ui, da bin ich wohl vom Ast gefallen. Irgendwas hat nicht geklappt! 🌳",
    "Halt die Backen steif! Es gab einen Fehler, aber wir schaffen das zusammen.",
    "Knusper, knusper... Knaster? Irgendwas knarzt hier im System herum.",
    "Oh nein, meine Nussleitung steht wohl gerade komplett auf dem Schlauch!",
    "Ein Fehler! Schnell, tu so als wärst du ein Strauch... oder probier es einfach noch mal! 🍃",
    "Meine Spürnase sagt: Das hat nicht geklappt. Gibst du mir noch eine Chance?",
  ];

  static final List<String> _duplicateMealMessages = [
    "Erledigt! Weil du es bist, habe ich die Daten besonders ordentlich sortiert. ✍️",
    "Eingetragen! Wenn ich könnte, würde ich dir jetzt eine kleine Service-Nuss reichen. 🥜",
    "Kopiert! Ich hab das direkt sauber in deine Übersicht geschoben. 🐿️",
    "Zack, erledigt! Weil lecker eben lecker bleibt! ✨",
    "Dein Wunsch ist mein Hörnchen-Befehl. Steht im System!",
    "Schwupps! Einmal Strg+C und Strg+V für deinen Plan. Perfekt erledigt!",
    "Erfolgreich gespeichert! Sicherer als mein geheimster Wintervorrat.",
    "Klick, klack, kopiert! Mein innerer Taschenrechner liebt diese Mahlzeit.",
    "Gute Wahl! Ich habe meine flauschigen Pfoten direkt flitzen lassen.",
    "Zack! Das steht jetzt bombenfest in deiner Übersicht. Lass es dir schmecken! 🍽️",
  ];

  static final List<String> _missingInputMessages = [
    "Knusper, knusper... häh? Mein Körbchen ist ja noch ganz leer. Magst du mir schnell schreiben, ein Foto dalassen oder eine Memo aufnehmen?",
    "Upsi, jetzt bin ich glatt über meinen eigenen Schwanz gestolpert! Aber sag mal... da fehlt noch Text, Bild oder Ton, oder?",
    "Wartemaaal! Mein Eichhörnchen-Gehirn schaltet gerade auf Leerlauf. Ich brauche ein Foto, Text oder deine Stimme!",
    "Oh... huch? Ich sehe gar nichts! Fütterst du mich mit ein paar Infos als Text, Bild oder Audio?",
    "Menno, ich wollte gerade schon wild losrechnen, aber mein Notizblock ist noch komplett leer! Schickst du mir kurz was?",
    "Äh... hast du vergessen, was einzutippen, zu knipsen oder reinzuquatschen? Ich sehe hier nämlich leider nüscht!",
    "Halt, stopp! Da hab ich vor Schreck fast eine Nuss fallen lassen! Ohne Text, Bild oder Ton weiß ich gar nicht, was ich tun soll. 🥜",
    "Uff, ich habe vor lauter Vorfreude mein schlaues Buch verlegt... und du hast mir ja auch noch gar nichts reingeschrieben oder fotografiert!",
    "Hallo? Jemand zu Hause? Ich klopfe mal vorsichtig an: Ich brauche ein Bild, Text oder ein bisschen Ton von dir!",
    "Hach, ich würde ja gerne loggen, aber du musst mir erst Text, Bild oder Audio geben! Los, trau dich! ✨",
  ];

  static final List<String> _deleteMealMessages = [
    "Und schwupps, weggewischt! Ich hab den Eintrag flink aus meinem Notizblock gestrichen. 📝",
    "Gelöscht! Ich hab das mal ganz tief im digitalen Wald vergraben. Findet niemand mehr!",
    "Weg ist es! Fast so spurlos verschwunden wie eine Nuss, die ich letzten Winter versteckt habe.",
    "Aussortiert! Platz gemacht in der Übersicht. Ich bin eben ein ordentliches Hörnchen. ✨",
    "Upsi, weggezaubert! Ich hab kurz den digitalen Radiergummi geschwungen – weg!",
    "Und tschüss! Ich habe das mal eben feinsäuberlich aus deiner Liste entfernt.",
    "Erledigt! Vom virtuellen Teller gefegt. Platz für Neues!",
    "Weggeputzt! Meine kleinen Pfoten haben im Nu wieder Ordnung in deiner Übersicht geschaffen.",
    "Gelöscht! Ich weiß von absolut gar nichts mehr. Mein Gedächtnis ist wieder blitzblank. 🐿️",
    "Zack, gelöscht! Sicherer und schneller weggeschafft als meine geheimen Wintervorräte.",
  ];

  static final List<String> _logoutMessages = [
    "Tschüss! Ich bleibe hier auf meinem Ast sitzen und warte ganz ungeduldig auf dich. 🐿️",
    "Mach's gut! Ich halte den Taschenrechner warm, bis du wieder da bist.",
    "Schon weg? Lass mir ein paar Krümel da! Bis zum nächsten Mal!",
    "Huch, du gehst schon? Ich winke dir mit beiden Pfoten hinterher. Komm schnell wieder!",
    "Schade, aber ruh dich schön aus! Ich freue mich jetzt schon riesig auf unseren nächsten Snack-Check.",
    "Bis bald! Ich passe so lange ganz besonders gut auf deine Übersicht auf, versprochen! 🥜",
    "Warte, nimm mich mit! ...Ach Quatsch, ich passe hier auf die App auf. Bis gleich!",
    "Mach's gut, mein Lieblingsmensch! Lass dir dein nächstes Essen schmecken! 🍽️",
    "Tschüssi! Ich drehe eine kleine Runde im Laufrad, bis du wieder reinschaust.",
    "Bis zum nächsten Mal! Vergiss nicht, genug zu trinken. Wir sehen uns später!",
  ];

  static String get randomGreeting =>
      _greetings[Random().nextInt(_greetings.length)];

  static String get randomErrorFallback =>
      _errorFallbacks[Random().nextInt(_errorFallbacks.length)];

  static String get randomDuplicateMealMessage =>
      _duplicateMealMessages[Random().nextInt(_duplicateMealMessages.length)];

  static String get randomMissingInputMessage =>
      _missingInputMessages[Random().nextInt(_missingInputMessages.length)];

  static String get randomDeleteMealMessage =>
      _deleteMealMessages[Random().nextInt(_deleteMealMessages.length)];

  static String get randomLogoutMessage =>
      _logoutMessages[Random().nextInt(_logoutMessages.length)];
}

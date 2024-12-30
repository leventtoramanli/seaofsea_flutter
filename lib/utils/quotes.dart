import 'dart:math';

class Quotes {
  static const List<String> seaQuotes = [
    "Sailing from one harbor to another, every step writes a story.",
    "The sea is an endless map where every traveler finds their own star.",
    "The darker the sky, the brighter the stars guide the way.",
    "A ship is safe in the harbor, but that’s not what ships are built for.",
    "For a sailor, obstacles are just the beginning of discovering new routes.",
    "Don’t resist the waves; learn to ride with them.",
    "A sailor’s compass is their determination.",
    "Freedom lies in the skies and seas of a nation’s soul.",
    "Those who gaze at the horizon see opportunities, not obstacles.",
    "Life is like the sea; sometimes turbulent, sometimes calm, but always deep.",
    "The sea teaches us patience, courage, and the value of living in the moment.",
    "The sea whispers: if you don’t set sail, you’ll never reach anywhere.",
    "Raising a sail takes courage, but only those who set out feel the wind’s strength.",
    "A storm is not always terrifying; sometimes it takes you to unexpected places."
  ];

  static String getRandomQuote() {
    final random = Random();
    return seaQuotes[random.nextInt(seaQuotes.length)];
  }
}

// song_model.dart

class SongModel {
  final String id; // Unique ID for each song
  final String title;
  final String artist;
  final String uri; // URI or path to the audio file
  final int duration; // Duration of the audio in milliseconds
  final String? albumArt; // Optional album art URL

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.uri,
    required this.duration,
    this.albumArt,
  });

  // Factory constructor to create a SongModel from a map (from a file or other source)
  factory SongModel.fromMap(Map<String, dynamic> data) {
    return SongModel(
      id: data['id'] ?? DateTime.now().toString(), // Generate a unique ID if not provided
      title: data['title'] ?? 'Unknown Title',
      artist: data['artist'] ?? 'Unknown Artist',
      uri: data['uri'] ?? '',
      duration: data['duration'] ?? 0,
      albumArt: data['albumArt'],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';

// ==========================================
// 1. THEME COLORS (Wood & Coffee)
// ==========================================
class AppColors {
  static const Color darkCoffee = Color(0xFF1E130C);
  static const Color coffeeBrown = Color(0xFF3E2723);
  static const Color woodAccent = Color(0xFFD84315);
  static const Color textPrimary = Color(0xFFF5F5DC);
  static const Color textSecondary = Color(0xFFBCAAA4);
}

// ==========================================
// 2. SONG MODEL
// ==========================================
class Song {
  final String id;
  final String title;
  final String artist;
  final String thumbnail;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.thumbnail,
  });
}

// ==========================================
// 3. PLAYER STATE MANAGEMENT
// ==========================================
class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  Song? _currentSong;
  bool _isPlaying = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;

  PlayerProvider() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
  }

  Future<void> playSong(Song song) async {
    _currentSong = song;
    notifyListeners();

    try {
      // Filhal ek dummy audio chalega, baad mein isko yt-dlp se replace karenge
      final source = AudioSource.uri(
        Uri.parse("https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"),
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: Uri.parse(song.thumbnail),
        ),
      );
      await _player.setAudioSource(source);
      _player.play();
    } catch (e) {
      print("Player Error: $e");
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }
}

// ==========================================
// 4. MAIN FUNCTION & APP
// ==========================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.woodytune.channel.audio',
    androidNotificationChannelName: 'WoodyTune Playback',
    androidNotificationOngoing: true,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WoodyTune',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkCoffee,
        primaryColor: AppColors.woodAccent,
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScreen(),
    );
  }
}

// ==========================================
// 5. MAIN SCREEN (Bottom Navigation)
// ==========================================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _index,
                children: const [
                  HomeScreen(),
                  Center(child: Text("Search Screen (Coming Soon)", style: TextStyle(color: AppColors.textSecondary))),
                  Center(child: Text("Library Screen (Coming Soon)", style: TextStyle(color: AppColors.textSecondary))),
                ],
              ),
            ),
            const MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: AppColors.darkCoffee,
        selectedItemColor: AppColors.woodAccent,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
        ],
      ),
    );
  }
}

// ==========================================
// 6. HOME SCREEN UI
// ==========================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songs = [
      Song(id: '1', title: 'Shape of You', artist: 'Ed Sheeran', thumbnail: 'https://i.ytimg.com/vi/JGwWNGJdvx8/hqdefault.jpg'),
      Song(id: '2', title: 'Despacito', artist: 'Luis Fonsi', thumbnail: 'https://i.ytimg.com/vi/kJQP7kiw5Fk/hqdefault.jpg'),
      Song(id: '3', title: 'Gangnam Style', artist: 'PSY', thumbnail: 'https://i.ytimg.com/vi/9bZkp7q19f0/hqdefault.jpg'),
      Song(id: '4', title: 'Believer', artist: 'Imagine Dragons', thumbnail: 'https://i.ytimg.com/vi/7wtfhZwyrcc/hqdefault.jpg'),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'WoodyTune ☕',
          style: TextStyle(color: AppColors.woodAccent, fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Good Evening", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          ...songs.map((song) => GestureDetector(
            onTap: () => context.read<PlayerProvider>().playSong(song),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.coffeeBrown,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: song.thumbnail, 
                    width: 50, 
                    height: 50, 
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Icon(Icons.music_note, color: Colors.white),
                    errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  ),
                ),
                title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                subtitle: Text(song.artist, style: const TextStyle(color: AppColors.textSecondary)),
                trailing: const Icon(Icons.play_circle_fill, color: AppColors.woodAccent, size: 30),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }
}

// ==========================================
// 7. MINI PLAYER (Bottom Bar)
// ==========================================
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final song = provider.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.coffeeBrown,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: song.thumbnail,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
            trailing: IconButton(
              icon: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.woodAccent,
                size: 32,
              ),
              onPressed: provider.togglePlay,
            ),
          ),
        );
      },
    );
  }
}
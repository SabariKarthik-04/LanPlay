import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'dart:math' as math;

import '../model/media_item.dart';
import '../utils/api.dart';

class MusicPlayerPage extends StatefulWidget {
  final MediaItemModel song;
  final List<MediaItemModel> playlist;
  final int currentIndex;

  const MusicPlayerPage({
    super.key,
    required this.song,
    required this.playlist,
    required this.currentIndex,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Player player;
  late MediaItemModel currentSong;
  late int currentIndex;
  bool isPlaying = false;
  bool isShuffled = false;
  bool isRepeat = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    currentSong = widget.song;
    currentIndex = widget.currentIndex;
    player = Player();
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _setupPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _setupPlayer() {
    player.open(Media(buildStreamUrl(currentSong.relativePath)));

    player.stream.playing.listen((playing) {
      if (mounted) {
        setState(() => isPlaying = playing);
        if (playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    player.stream.position.listen((pos) {
      if (mounted) {
        setState(() => position = pos);
      }
    });

    player.stream.duration.listen((dur) {
      if (mounted) {
        setState(() => duration = dur);
      }
    });

    player.stream.completed.listen((completed) {
      if (completed && mounted) {
        _playNext();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _playPause() {
    if (isPlaying) {
      player.pause();
    } else {
      player.play();
    }
  }

  void _playNext() {
    if (currentIndex < widget.playlist.length - 1) {
      setState(() {
        currentIndex++;
        currentSong = widget.playlist[currentIndex];
      });
      player.open(Media(buildStreamUrl(currentSong.relativePath)));
    } else if (isRepeat) {
      setState(() {
        currentIndex = 0;
        currentSong = widget.playlist[0];
      });
      player.open(Media(buildStreamUrl(currentSong.relativePath)));
    }
  }

  void _playPrevious() {
    if (position.inSeconds > 3) {
      player.seek(Duration.zero);
    } else if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        currentSong = widget.playlist[currentIndex];
      });
      player.open(Media(buildStreamUrl(currentSong.relativePath)));
    }
  }

  void _toggleShuffle() {
    setState(() => isShuffled = !isShuffled);
  }

  void _toggleRepeat() {
    setState(() => isRepeat = !isRepeat);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Generate unique gradient colors based on song title
  List<Color> _getGradientColors() {
    final hash = currentSong.title.hashCode;
    final random = math.Random(hash);
    
    final hue = random.nextDouble() * 360;
    return [
      HSLColor.fromAHSL(1.0, hue, 0.7, 0.6).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 30) % 360, 0.8, 0.5).toColor(),
      HSLColor.fromAHSL(1.0, (hue + 60) % 360, 0.7, 0.4).toColor(),
    ];
  }

  Widget _buildAlbumArt() {
    return _buildDummyArt();
  }

  Widget _buildDummyArt() {
    final colors = _getGradientColors();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background pattern
          Opacity(
            opacity: 0.1,
            child: CustomPaint(
              size: const Size(280, 280),
              painter: MusicPatternPainter(),
            ),
          ),
          // Music icon
          const Icon(
            Icons.music_note_rounded,
            size: 120,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade400,
                Colors.purple.shade600,
                Colors.deepPurple.shade800,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                        color: Colors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'from ${widget.playlist.length} songs',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Album art
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Hero(
                    tag: 'album_${currentSong.title}',
                    child: RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAlbumArt(),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Song info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unknown Artist',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          overlayColor: Colors.white.withOpacity(0.3),
                        ),
                        child: Slider(
                          value: position.inSeconds.toDouble(),
                          min: 0,
                          max: duration.inSeconds > 0
                              ? duration.inSeconds.toDouble()
                              : 1.0,
                          onChanged: (value) {
                            player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          isShuffled ? Icons.shuffle_on_outlined : Icons.shuffle,
                          color: isShuffled
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                        ),
                        iconSize: 28,
                        onPressed: _toggleShuffle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        color: Colors.white,
                        iconSize: 42,
                        onPressed: _playPrevious,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.deepPurple,
                          ),
                          iconSize: 50,
                          onPressed: _playPause,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        color: Colors.white,
                        iconSize: 42,
                        onPressed: _playNext,
                      ),
                      IconButton(
                        icon: Icon(
                          isRepeat
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: isRepeat
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                        ),
                        iconSize: 28,
                        onPressed: _toggleRepeat,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Additional controls
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        color: Colors.white.withOpacity(0.7),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music),
                        color: Colors.white.withOpacity(0.7),
                        onPressed: () {
                          _showPlaylist();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPlaylist() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Queue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.playlist.length} songs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: widget.playlist.length,
                itemBuilder: (context, index) {
                  final song = widget.playlist[index];
                  final isCurrent = index == currentIndex;
                  return ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isCurrent
                            ? Colors.deepPurple.withOpacity(0.2)
                            : Colors.grey[200],
                      ),
                      child: Center(
                        child: Icon(
                          isCurrent ? Icons.play_arrow : Icons.music_note,
                          color: isCurrent ? Colors.deepPurple : Colors.grey,
                        ),
                      ),
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? Colors.deepPurple : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Text('Unknown Artist'),
                    onTap: () {
                      setState(() {
                        currentIndex = index;
                        currentSong = song;
                      });
                      player.open(Media(buildStreamUrl(song.relativePath)));
                      Navigator.pop(context);
                    },
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

// Custom painter for background pattern
class MusicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw some music notes pattern
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    for (var i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      
      canvas.drawCircle(Offset(x, y), 8, paint);
    }

    // Draw center circle
    canvas.drawCircle(center, 20, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
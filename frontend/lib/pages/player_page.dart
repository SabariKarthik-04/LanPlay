import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../model/media_item.dart';
import '../utils/api.dart';

class PlayerPage extends StatefulWidget {
  final MediaItemModel media;
  const PlayerPage({super.key, required this.media});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late final Player player;
  late final VideoController controller;

  bool showControls = true;
  bool isFullscreen = false;
  bool isLocked = false;
  double currentSpeed = 1.0;
  double currentVolume = 1.0;
  bool isMuted = false;

  final List<double> speedOptions = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    player = Player();
    controller = VideoController(player);

    player.open(Media(buildStreamUrl(widget.media.relativePath)));
    
    // Initialize subtitle detection and logging
    _initializeSubtitles();
    _logSubtitleTracks();

    // Auto-hide controls after 3 seconds
    _startControlsTimer();
  }

  void _startControlsTimer() {
    if (isLocked) return; // Don't auto-hide if locked
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && showControls && !isLocked) {
        setState(() => showControls = false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      player.pause();
    } else if (state == AppLifecycleState.resumed) {
      player.play();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    player.dispose();
    super.dispose();
  }

  void skip(Duration offset) {
    final position = player.state.position;
    final duration = player.state.duration;
    final target = position + offset;

    final safeTarget = target < Duration.zero
        ? Duration.zero
        : (duration != null && target > duration)
            ? duration
            : target;

    player.seek(safeTarget);
  }

  void toggleFullscreen() {
    setState(() {
      isFullscreen = !isFullscreen;
      if (isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    });
  }

  void changeSpeed(double speed) {
    setState(() => currentSpeed = speed);
    player.setRate(speed);
  }

  void toggleMute() {
    setState(() {
      isMuted = !isMuted;
      player.setVolume(isMuted ? 0 : currentVolume * 100);
    });
  }

  void setVolume(double volume) {
    setState(() {
      currentVolume = volume;
      isMuted = false;
      player.setVolume(volume * 100);
    });
  }

  // Wait briefly for tracks to load and force a UI refresh if subtitles appear
  void _initializeSubtitles() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final tracks = player.state.tracks;
    if (tracks.subtitle.isNotEmpty) {
      // Optionally auto-select the first subtitle track:
      // player.setSubtitleTrack(tracks.subtitle.first);

      if (mounted) setState(() {});
    }
  }

  // Debug helper to log subtitle track changes
  void _logSubtitleTracks() {
    player.stream.tracks.listen((tracks) {
      // ignore: avoid_print
      print('Available subtitle tracks: ${tracks.subtitle.length}');
      for (var track in tracks.subtitle) {
        // ignore: avoid_print
        print('Subtitle: ${track.id} - ${track.title} - ${track.language}');
      }
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: WillPopScope(
        onWillPop: () async {
          if (isFullscreen) {
            toggleFullscreen();
            return false;
          }
          return true;
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video with controls hidden
            Video(
              controller: controller,
              fit: BoxFit.contain,
              controls: NoVideoControls, // Hide default controls
            ),

            // Our custom controls
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  if (isLocked) return; // Ignore taps when locked
                  setState(() {
                    showControls = !showControls;
                  });
                  if (showControls) _startControlsTimer();
                },
                onDoubleTapDown: (details) {
                  if (isLocked) return; // Ignore double taps when locked
                  final screenWidth = MediaQuery.of(context).size.width;
                  final tapPosition = details.globalPosition.dx;
                  
                  // Double tap left side to skip back, right side to skip forward
                  if (tapPosition < screenWidth / 2) {
                    skip(const Duration(seconds: -10));
                  } else {
                    skip(const Duration(seconds: 10));
                  }
                },
                child: Container(
                  color: Colors.transparent,
                  child: IgnorePointer(
                    ignoring: !showControls,
                    child: AnimatedOpacity(
                      opacity: showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: _buildControls(context),
                    ),
                  ),
                ),
              ),
            ),

            // Lock button (always visible)
            if (isFullscreen)
              Positioned(
                left: 16,
                top: MediaQuery.of(context).padding.top + 50,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      isLocked = !isLocked;
                      if (isLocked) {
                        showControls = false;
                      } else {
                        showControls = true;
                        _startControlsTimer();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLocked ? Icons.lock : Icons.lock_open,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),

            // Loading indicator
            StreamBuilder<bool>(
              stream: player.stream.buffering,
              builder: (_, snapshot) {
                final isBuffering = snapshot.data ?? false;
                return isBuffering
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar
          _buildTopBar(context),

          // Center controls
          if (!isLocked) _buildCenterControls(),

          // Bottom bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.media.title ?? 'Video Player',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildSpeedButton(),
            _audioButton(),
            _subtitleButton(),
            _buildVolumeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildControlButton(
          icon: Icons.replay_10,
          onPressed: () => skip(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 20),
        StreamBuilder<bool>(
          stream: player.stream.playing,
          builder: (_, snapshot) {
            final playing = snapshot.data ?? false;
            return _buildControlButton(
              icon: playing ? Icons.pause : Icons.play_arrow,
              size: 70,
              onPressed: () => playing ? player.pause() : player.play(),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildControlButton(
          icon: Icons.forward_10,
          onPressed: () => skip(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 50,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: size,
        color: Colors.white,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBottomBar() {
    return Column(
      children: [
        // Progress bar
        _buildProgressBar(),
        
        // Time and fullscreen
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              StreamBuilder<Duration>(
                stream: player.stream.position,
                builder: (_, posSnap) {
                  return StreamBuilder<Duration>(
                    stream: player.stream.duration,
                    builder: (_, durSnap) {
                      final position = posSnap.data ?? Duration.zero;
                      final duration = durSnap.data ?? Duration.zero;
                      return Text(
                        '${_formatDuration(position)} / ${_formatDuration(duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  );
                },
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: Colors.white,
                ),
                onPressed: toggleFullscreen,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (_, posSnap) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          builder: (_, durSnap) {
            final position = posSnap.data ?? Duration.zero;
            final duration = durSnap.data ?? Duration.zero;
            
            final maxValue = duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
            final currentValue = position.inSeconds.toDouble().clamp(0.0, maxValue);

            return SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 6,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 14,
                ),
                activeTrackColor: Theme.of(context).primaryColor,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Theme.of(context).primaryColor,
                overlayColor: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
              child: Slider(
                value: currentValue,
                min: 0.0,
                max: maxValue,
                onChanged: (value) {
                  player.seek(Duration(seconds: value.toInt()));
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSpeedButton() {
    return PopupMenuButton<double>(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '${currentSpeed}x',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      color: Colors.black87,
      itemBuilder: (context) => speedOptions
          .map(
            (speed) => PopupMenuItem<double>(
              value: speed,
              child: Row(
                children: [
                  if (speed == currentSpeed)
                    const Icon(Icons.check, color: Colors.white, size: 18)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${speed}x',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: speed == currentSpeed
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      onSelected: changeSpeed,
    );
  }

  Widget _buildVolumeButton() {
    return PopupMenuButton(
      icon: Icon(
        isMuted ? Icons.volume_off : Icons.volume_up,
        color: Colors.white,
      ),
      color: Colors.black87,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: StatefulBuilder(
            builder: (context, setSliderState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Volume',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () {
                          toggleMute();
                          setSliderState(() {});
                        },
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Theme.of(context).primaryColor,
                    ),
                    child: Slider(
                      value: isMuted ? 0 : currentVolume,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setVolume(value);
                        setSliderState(() {});
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _audioButton() {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      builder: (_, snapshot) {
        final tracks = snapshot.data?.audio ?? [];
        if (tracks.length <= 1) return const SizedBox();

        return IconButton(
          icon: const Icon(Icons.audiotrack, color: Colors.white),
          onPressed: () async {
            final selected = await _showTrackDialog(
              context,
              'Select Audio Track',
              tracks.map((e) => e.language ?? e.id).toList(),
            );

            if (selected != null) {
              player.setAudioTrack(
                tracks.firstWhere((e) => (e.language ?? e.id) == selected),
              );
            }
          },
        );
      },
    );
  }

  Widget _subtitleButton() {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      builder: (_, snapshot) {
        final subtitleTracks = snapshot.data?.subtitle ?? [];

        // Always show subtitle button; disable if no tracks yet
        return IconButton(
          icon: Icon(
            Icons.subtitles,
            color: subtitleTracks.isEmpty
                ? Colors.white.withOpacity(0.5)
                : Colors.white,
          ),
          onPressed: subtitleTracks.isEmpty
              ? null
              : () async {
                  final selected = await _showTrackDialog(
                    context,
                    'Select Subtitles',
                    ['Off', ...subtitleTracks.map((e) => e.language ?? e.title ?? e.id)],
                  );

                  if (selected == 'Off') {
                    player.setSubtitleTrack(SubtitleTrack.no());
                  } else if (selected != null) {
                    player.setSubtitleTrack(
                      subtitleTracks.firstWhere(
                        (e) => (e.language ?? e.title ?? e.id) == selected,
                      ),
                    );
                  }
                },
        );
      },
    );
  }

  Future<String?> _showTrackDialog(
    BuildContext context,
    String title,
    List<String> options,
  ) {
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map(
                  (e) => ListTile(
                    title: Text(
                      e,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () => Navigator.pop(context, e),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    hoverColor: Colors.white.withOpacity(0.1),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
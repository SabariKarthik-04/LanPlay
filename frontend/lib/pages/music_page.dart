import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/music_player.dart';
import 'package:http/http.dart' as http;

import '../model/media_item.dart';
import '../utils/api.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> with SingleTickerProviderStateMixin {
  List<MediaItemModel> songs = [];
  Map<String, List<MediaItemModel>> albums = {};
  Map<String, List<MediaItemModel>> artists = {};
  bool isLoading = true;
  String? errorMessage;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadMusic();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadMusic() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final res = await http.get(Uri.parse("${ApiConfig.serverBase}/library"));

      if (res.statusCode != 200) {
        throw Exception('Failed to load music');
      }

      final data = json.decode(res.body);
      final List<dynamic> musicJson = data["music"] ?? [];

      final List<MediaItemModel> parsed = musicJson.map((m) {
        return MediaItemModel(
          title: m["name"],
          thumbnail: m["thumbnail"] != null ? buildThumbnailUrl(m["thumbnail"]) : "",
          relativePath: "music/${m["name"]}",
        );
      }).toList();

      // Group by albums and artists
      final Map<String, List<MediaItemModel>> albumsMap = {};
      final Map<String, List<MediaItemModel>> artistsMap = {};

      for (var song in parsed) {
        String albumName = "Unknown Album";
        if (!albumsMap.containsKey(albumName)) {
          albumsMap[albumName] = [];
        }
        albumsMap[albumName]!.add(song);

        String artistName = "Unknown Artist";
        if (!artistsMap.containsKey(artistName)) {
          artistsMap[artistName] = [];
        }
        artistsMap[artistName]!.add(song);
      }

      setState(() {
        songs = parsed;
        albums = albumsMap;
        artists = artistsMap;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Music Library',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50,
                        top: -50,
                        child: Icon(
                          Icons.music_note,
                          size: 200,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: -30,
                        bottom: -30,
                        child: Icon(
                          Icons.headphones,
                          size: 150,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Songs', icon: Icon(Icons.music_note, size: 20)),
                  Tab(text: 'Albums', icon: Icon(Icons.album, size: 20)),
                  Tab(text: 'Artists', icon: Icon(Icons.person, size: 20)),
                ],
              ),
            ),
          ];
        },
        body: _buildBody(),
      ),
      floatingActionButton: songs.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _shufflePlay(),
              icon: const Icon(Icons.shuffle),
              label: const Text('Shuffle All'),
              backgroundColor: Colors.deepPurple,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading music...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to load music',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loadMusic,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No music available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildSongsView(),
        _buildAlbumsView(),
        _buildArtistsView(),
      ],
    );
  }

  Widget _buildSongsView() {
    return RefreshIndicator(
      onRefresh: loadMusic,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          return _buildSongTile(song, index);
        },
      ),
    );
  }

  Widget _buildSongTile(MediaItemModel song, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnail.isNotEmpty
                  ? Image.network(
                      song.thumbnail,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
                    )
                  : _buildDefaultThumbnail(),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.deepPurple,
                size: 18,
              ),
            ),
          ],
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: const Text(
          'Unknown Artist',
          style: TextStyle(fontSize: 13),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'play',
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 20),
                  SizedBox(width: 12),
                  Text('Play'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'queue',
              child: Row(
                children: [
                  Icon(Icons.queue_music, size: 20),
                  SizedBox(width: 12),
                  Text('Add to queue'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, size: 20),
                  SizedBox(width: 12),
                  Text('Add to playlist'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _playSong(song, index),
      ),
    );
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade300,
            Colors.deepPurple.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildAlbumsView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums.entries.elementAt(index);
        return _buildAlbumCard(album.key, album.value);
      },
    );
  }

  Widget _buildAlbumCard(String albumName, List<MediaItemModel> songs) {
    return GestureDetector(
      onTap: () {
        _playSong(songs.first, 0);
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    songs.first.thumbnail.isNotEmpty
                        ? Image.network(
                            songs.first.thumbnail,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultAlbumArt(),
                          )
                        : _buildDefaultAlbumArt(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${songs.length} song${songs.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade300,
            Colors.deepPurple.shade500,
          ],
        ),
      ),
      child: const Icon(
        Icons.album,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildArtistsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists.entries.elementAt(index);
        return _buildArtistTile(artist.key, artist.value);
      },
    );
  }

  Widget _buildArtistTile(String artistName, List<MediaItemModel> songs) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.deepPurple.shade100,
          child: Icon(
            Icons.person,
            color: Colors.deepPurple,
            size: 28,
          ),
        ),
        title: Text(
          artistName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text('${songs.length} song${songs.length != 1 ? 's' : ''}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          _playSong(songs.first, 0);
        },
      ),
    );
  }

  void _playSong(MediaItemModel song, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerPage(
          song: song,
          playlist: songs,
          currentIndex: index,
        ),
      ),
    );
  }

  void _shufflePlay() {
    final shuffled = List<MediaItemModel>.from(songs)..shuffle();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerPage(
          song: shuffled.first,
          playlist: shuffled,
          currentIndex: 0,
        ),
      ),
    );
  }
}
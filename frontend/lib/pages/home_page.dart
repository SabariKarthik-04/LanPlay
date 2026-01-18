import 'package:flutter/material.dart';
import 'series_page.dart';
import 'movies_page.dart';
import 'music_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing
    final appBarHeight = screenHeight * 0.25;
    final categoryCardHeight = screenHeight * 0.16;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern app bar with gradient
          SliverAppBar(
            expandedHeight: appBarHeight,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Media Library',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.055,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.movie_filter,
                        size: screenWidth * 0.5,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Icon(
                        Icons.play_circle_outline,
                        size: screenWidth * 0.35,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Browse Content',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.055,
                        ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Choose a category to explore',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.03),

                  // Main categories
                  _buildCategoryCard(
                    context,
                    title: 'Movies',
                    subtitle: 'Watch your favorite films',
                    icon: Icons.movie_creation,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE91E63), Color(0xFFF50057)],
                    ),
                    height: categoryCardHeight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoviesPage()),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildCategoryCard(
                    context,
                    title: 'TV Series',
                    subtitle: 'Binge your favorite shows',
                    icon: Icons.tv,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3F51B5), Color(0xFF5C6BC0)],
                    ),
                    height: categoryCardHeight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SeriesPage()),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  _buildCategoryCard(
                    context,
                    title: 'Music',
                    subtitle: 'Listen to your favorite tracks',
                    icon: Icons.library_music,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF9C27B0), Color(0xFFAB47BC)],
                    ),
                    height: categoryCardHeight,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MusicPage()),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required double height,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Stack(
            children: [
              // Background icon
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  icon,
                  size: height * 1.1,
                  color: Colors.white.withOpacity(0.2),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(screenWidth * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      ),
                      child: Icon(
                        icon,
                        size: screenWidth * 0.07,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: height * 0.08),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: screenWidth * 0.033,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Positioned(
                right: screenWidth * 0.03,
                bottom: screenWidth * 0.03,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: screenWidth * 0.05,
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
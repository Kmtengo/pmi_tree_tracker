import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tree_view_model.dart';
import '../view_models/user_view_model.dart';
import '../widgets/pmi_button_styles.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F0E9), // 25% heavier mint-cream background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PMI-Kenya Initiative Section
              Container(
                margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9), // Light off-white background
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left column with text (2/3 width)
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PMI-Kenya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF222222),
                                height: 1.1,
                              ),
                              children: [
                                TextSpan(text: 'Tree Planting\n'),
                                TextSpan(
                                  text: 'Initiative',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),                    // Right column with Kenya map image (1/3 width)
                    const Expanded(
                      flex: 1,
                      child: Image(
                        image: AssetImage('assets/images/kenya_map.png'),
                        color: Color(0xFF7E57C2), // Muted purple color
                        height: 120, // Increased from 80 for better visibility
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
                // Status cards section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: SizedBox(
                  height: 190, // Increased to 190px as requested
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      StatusCard(
                        backgroundColor: const Color(0xFF345A33),
                        iconData: Icons.local_florist,
                        title: 'Trees planted (total)',
                        subtitle: 'Grows paradise\nA plantita y planter',
                        buttonText: 'Add new planting',
                        buttonColor: Colors.lightGreen[100]!,
                        onButtonPressed: () {
                          // Navigate to planting screen
                        },
                        onCardTap: () {
                          // Show tree details
                        },
                      ),
                      const SizedBox(width: 15),
                      StatusCard(
                        backgroundColor: const Color(0xFF0DD7E6),
                        iconData: Icons.article,
                        title: 'Active projects',
                        subtitle: 'Stocking where\nAn earthy realm of activities',
                        buttonText: 'Upload growth update',
                        buttonColor: Colors.lightBlue[100]!,
                        buttonTextStyle: const TextStyle(
                          fontSize: 8.5, // Reduced by 0.5px from 9.0
                          fontWeight: FontWeight.w600,
                        ),
                        onButtonPressed: () {
                          // Navigate to upload screen
                        },
                        onCardTap: () {
                          // Show projects
                        },
                      ),
                      const SizedBox(width: 15),
                      StatusCard(
                        backgroundColor: const Color(0xFFF58804),
                        iconData: Icons.verified_user,
                        title: 'Pending verifications',
                        subtitle: 'Seeds planted\nA promise fulfilled',
                        buttonText: 'View updates',
                        buttonColor: const Color(0xFFFDCFBC), // Light peach
                        onButtonPressed: () {
                          // Navigate to verification screen
                        },
                        onCardTap: () {
                          // Show pending verifications
                        },                      ),
                    ],
                  ),
                ),
              ),              // Activity feed header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
                child: SectionHeader(
                  title: 'Activity Updates!',
                  onMorePressed: () {
                    // Show more activities
                  },
                ),
              ),

              // Activity feed items
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
                child: Column(
                  children: [
                    ActivityItem(
                      title: 'You logged 12 trees in Kisumu',
                      subtitle: '5 requests in time 00:12',
                      iconData: Icons.forest,
                      isFavorite: false,
                      onFavoritePressed: () {
                        // Toggle favorite status
                      },
                    ),
                    const SizedBox(height: 9), // Reduced from 18
                    ActivityItem(
                      title: 'Upload voveh atees poow approval',
                      subtitle: 'Mating art A4',
                      iconData: Icons.forest,
                      isFavorite: false,
                      onFavoritePressed: () {
                        // Toggle favorite status
                      },
                    ),
                    const SizedBox(height: 9), // Reduced from 18
                    ActivityItem(
                      title: '3 photos pending approval',
                      subtitle: 'Manes and puds /12274',
                      iconData: Icons.forest,
                      isFavorite: false,
                      onFavoritePressed: () {
                        // Toggle favorite status
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  final Color backgroundColor;
  final IconData iconData;
  final String title;
  final String subtitle;
  final String buttonText;
  final Color buttonColor;
  final TextStyle? buttonTextStyle;
  final VoidCallback onButtonPressed;
  final VoidCallback onCardTap;

  const StatusCard({
    super.key,
    required this.backgroundColor,
    required this.iconData,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.buttonColor,
    this.buttonTextStyle,
    required this.onButtonPressed,
    required this.onCardTap,
  });
  @override  Widget build(BuildContext context) {
    // Recalculate card width to ensure all 3 cards fit on screen with better spacing
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = 32.0; // 16.0 on each side
    final cardSpacing = 30.0; // 15.0 between each of the 3 cards (2 spaces)
    final availableWidth = screenWidth - horizontalPadding - cardSpacing;
    // Adding 2px to each card's width as requested
    final cardWidth = (availableWidth / 3) + 2; 
    
    return GestureDetector(
      onTap: onCardTap,
      child: Container(
        width: cardWidth,
        height: 190, // Increased to 190px as requested
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with icon and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500, // Reduced by 25% from bold (w700) to medium (w500)
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onButtonPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: buttonTextStyle ?? const TextStyle(
                      fontSize: 9.2, // Reduced by 1px from 10.2
                      fontWeight: FontWeight.w600,
                    ),
                    elevation: 0,
                  ),
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMorePressed;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2D6D4B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_right,
              color: Color(0xFF2D6D4B),
            ),
            onPressed: onMorePressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  const ActivityItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.onFavoritePressed,
    required this.isFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9), // Reduced from 18
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1.5, // Reduced from 3
            offset: const Offset(0, 0.75), // Reduced from (0, 1.5)
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), // Reduced from 24/18
        child: Row(
          children: [
            // Leading icon
            Container(
              width: 27, // Reduced from 54
              height: 27, // Reduced from 54
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6), // Reduced from 12
              ),
              child: Icon(
                iconData,
                color: const Color(0xFF063B04),
                size: 15, // Reduced from 30
              ),
            ),
            
            const SizedBox(width: 12), // Reduced from 24
            
            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12, // Reduced from 24
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10, // Reduced from 21
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Favorite button
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: const Color(0xFF063B04),
                size: 15, // Reduced from 30
              ),
              onPressed: onFavoritePressed,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24), // Reduced from 48/48
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

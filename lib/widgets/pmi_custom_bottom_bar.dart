import 'package:flutter/material.dart';
import '../utils/pmi_colors.dart';

class PMICustomBottomAppBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabTapped;

  const PMICustomBottomAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });
  // Using color definitions from PMIColors
  @override
  Widget build(BuildContext context) {    return Container(
      height: 60, // Increased to fix overflow (was 56)
      decoration: BoxDecoration(
        color: PMIColors.mintCream.withValues(
          alpha: 255, // Full opacity
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.1, // Reduced opacity for softer shadow
            ),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,        children: [
          _buildTab(context, 0, Icons.home_rounded, "Home"),
          _buildTab(context, 1, Icons.add_circle_rounded, "Add"),
          _buildTab(context, 2, Icons.location_on_rounded, "Map"),
          _buildTab(context, 3, Icons.article_rounded, "Reports"),
        ],
      ),
    );
  }
  Widget _buildTab(BuildContext context, int index, IconData icon, String label) {
    final isActive = currentIndex == index;
      return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onTabTapped(index),
        splashColor: PMIColors.teaGreen,
        hoverColor: PMIColors.honeydew,        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: MediaQuery.of(context).size.width / 4, // 25% of screen width (4 tabs)
          padding: const EdgeInsets.symmetric(vertical: 5), // Reduced padding from 8 to 5
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [              if (isActive)
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(                        height: 42, // Reduced from 44
                        width: 42, // Reduced from 44
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PMIColors.forestGreen,
                          boxShadow: [
                            BoxShadow(
                              color: PMIColors.forestGreen.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    );
                  },
                )
              else
                Column(
                  children: [                    Icon(
                      icon,
                      color: PMIColors.charcoal,
                      size: 24,
                    ),                    const SizedBox(height: 2), // Reduced from 4 to 2
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: "Segoe UI",
                        color: PMIColors.charcoal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

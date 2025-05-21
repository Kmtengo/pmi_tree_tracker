import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tree_view_model.dart';
import '../view_models/project_view_model.dart';
import '../models/tree_models.dart';
import '../widgets/leaf_pattern_background.dart';
import '../widgets/pmi_button_styles.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when dashboard is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TreeViewModel>(context, listen: false).loadTrees();
      Provider.of<ProjectViewModel>(context, listen: false).loadProjects();
    });
  }
  @override
  Widget build(BuildContext context) {    return LeafPatternBackground(
      isFormPage: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Consumer<TreeViewModel>(
          builder: (context, treeViewModel, child) {
            if (treeViewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (treeViewModel.error != null) {
              return Center(
                child: Text(
                  'Error loading data: ${treeViewModel.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }

            // Calculate statistics
            int treesPlanted = treeViewModel.trees.fold(0, (sum, tree) => sum + tree.quantity);
            int projects = 3; // Mock data for now
            double hectaresRestored = treesPlanted / 400; // Rough estimate

            return RefreshIndicator(
              onRefresh: () => treeViewModel.loadTrees(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsSection(
                        context: context,
                        treesPlanted: treesPlanted,
                        projects: projects,
                        hectaresRestored: hectaresRestored,
                      ),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(
                        context: context,
                        trees: treeViewModel.trees,
                      ),
                      const SizedBox(height: 24),
                      _buildProjectsSection(context),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatisticsSection({
    required BuildContext context,
    required int treesPlanted,
    required int projects,
    required double hectaresRestored,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Impact Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  context: context,
                  icon: Icons.eco,
                  value: '$treesPlanted',
                  label: 'Trees\nPlanted',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _buildStatCard(
                  context: context,
                  icon: Icons.forest,
                  value: hectaresRestored.toStringAsFixed(1),
                  label: 'Hectares\nRestored',
                  color: Theme.of(context).colorScheme.secondary,
                ),
                _buildStatCard(
                  context: context,
                  icon: Icons.group_work,
                  value: '$projects',
                  label: 'Active\nProjects',
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection({
    required BuildContext context,
    required List<Tree> trees,
  }) {
    final List<Tree> recentTrees = trees.length > 5
        ? trees.sublist(0, 5)
        : trees;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.arrow_forward),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTrees.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No recent tree planting activity',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTrees.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final tree = recentTrees[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.eco,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      '${tree.quantity} ${tree.species} trees planted',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${tree.location} • ${_formatDate(tree.plantingDate)}',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onTap: () {
                      // Navigate to tree details
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildProjectsSection(BuildContext context) {
    return Consumer<ProjectViewModel>(
      builder: (context, projectViewModel, child) {
        if (projectViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (projectViewModel.projects.isEmpty) {
          return const Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('No active projects found'),
              ),
            ),
          );
        }
        
        final displayProjects = projectViewModel.projects.map((project) {
          // Calculate progress percentage
          double progress = project.targetTrees > 0 
              ? project.plantedTrees / project.targetTrees 
              : 0.0;
          
          // Limit to 100%
          progress = progress > 1.0 ? 1.0 : progress;
          
          // Assign colors based on index
          Color color;
          int index = projectViewModel.projects.indexOf(project) % 3;
          switch (index) {
            case 0:
              color = Theme.of(context).colorScheme.primary;
              break;
            case 1:
              color = Theme.of(context).colorScheme.secondary;
              break;
            default:
              color = Theme.of(context).colorScheme.tertiary;
          }
          
          return {
            'name': project.title,
            'progress': progress,
            'color': color,
            'project': project,
          };
        }).toList();

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ongoing Projects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.arrow_forward),
                  ],
                ),
                const SizedBox(height: 16),
                ...displayProjects.map((project) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                project['name'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${((project['progress'] as double) * 100).toInt()}%',
                              style: TextStyle(
                                color: (project['color'] as Color),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: project['progress'] as double,
                          backgroundColor: (project['color'] as Color).withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(project['color'] as Color),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

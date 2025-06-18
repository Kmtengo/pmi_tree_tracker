import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tree_view_model.dart';
import '../models/tree_models.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1); // Jan 1 of current year
  DateTime _endDate = DateTime.now();
    @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load trees when reports screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TreeViewModel>(context, listen: false).loadTrees();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: Consumer<TreeViewModel>(
        builder: (context, treeViewModel, child) {
          if (treeViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (treeViewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${treeViewModel.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => treeViewModel.loadTrees(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Filter trees based on date range
          final filteredTrees = treeViewModel.trees.where((tree) {
            return tree.plantingDate.isAfter(_startDate) && 
                   tree.plantingDate.isBefore(_endDate.add(const Duration(days: 1)));
          }).toList();
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: _selectDateRange,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_drop_down,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.file_download,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading report...')),
                        );
                      },
                      tooltip: 'Export Report',
                    ),
                  ],
                ),
              ),              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Summary'),
                  Tab(text: 'By Species'),
                  Tab(text: 'By Team'),
                  Tab(text: 'Carbon Credits'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                indicatorColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                isScrollable: true, // Enable scrolling for 4 tabs
              ),              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Summary Tab
                    _buildSummaryTab(context, filteredTrees),
                    
                    // By Species Tab
                    _buildSpeciesTab(context, filteredTrees),
                    
                    // By Team Tab
                    _buildTeamTab(context, filteredTrees),
                    
                    // Carbon Credits Tab
                    _buildCarbonCreditsTab(context, filteredTrees),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSummaryTab(BuildContext context, List<Tree> trees) {
    // Calculate summary statistics
    final totalTrees = trees.fold(0, (sum, tree) => sum + tree.quantity);
    final totalPlantings = trees.length;
    final species = trees.map((e) => e.species).toSet().length;
    final teams = trees.where((t) => t.teamName != null).map((e) => e.teamName).toSet().length;
    
    // Create some mock monthly data
    final monthlyData = <String, int>{
      'Jan': 0, 'Feb': 0, 'Mar': 0, 'Apr': 0, 'May': 0, 'Jun': 0,
      'Jul': 0, 'Aug': 0, 'Sep': 0, 'Oct': 0, 'Nov': 0, 'Dec': 0,
    };
    
    for (var tree in trees) {
      final month = tree.plantingDate.month;
      final monthName = monthlyData.keys.elementAt(month - 1);
      monthlyData[monthName] = (monthlyData[monthName] ?? 0) + tree.quantity;
    }
    
    final maxMonthlyValue = monthlyData.values.fold(0, (max, value) => value > max ? value : max);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                context, 
                title: 'Total Trees', 
                value: totalTrees.toString(),
                icon: Icons.eco,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context, 
                title: 'Plantings', 
                value: totalPlantings.toString(),
                icon: Icons.place,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                context, 
                title: 'Species', 
                value: species.toString(),
                icon: Icons.category,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                context, 
                title: 'Teams', 
                value: teams.toString(),
                icon: Icons.group,
                color: const Color(0xFF662D91), // Purple
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Monthly Trends Chart
          const Text(
            'Monthly Planting Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 200,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthlyData.entries.map((entry) {
                    final double barHeight = maxMonthlyValue > 0
                        ? 140 * entry.value / maxMonthlyValue
                        : 0;
                    
                    return Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: barHeight,
                            width: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent Plantings
          const Text(
            'Recent Plantings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: trees.length > 5 ? 5 : trees.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final tree = trees[index];
                return ListTile(
                  title: Text(
                    '${tree.quantity} ${tree.species}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '${DateFormat('MMM d, y').format(tree.plantingDate)} • ${tree.location}',
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.eco,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSpeciesTab(BuildContext context, List<Tree> trees) {
    // Group trees by species
    final speciesMap = <String, int>{};
    for (var tree in trees) {
      speciesMap[tree.species] = (speciesMap[tree.species] ?? 0) + tree.quantity;
    }
    
    final speciesList = speciesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final totalTrees = trees.fold(0, (sum, tree) => sum + tree.quantity);
    
    final colors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      const Color(0xFF662D91), // Purple
    ];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pie Chart (simplified representation)
          const Text(
            'Distribution by Species',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 200,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Mock pie chart
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                          ),
                          ...List.generate(
                            speciesList.length > 4 ? 4 : speciesList.length,
                            (index) {
                              return Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors[index % colors.length],
                                      width: 25 * (speciesList[index].value / totalTrees),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Legend
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          speciesList.length > 4 ? 4 : speciesList.length,
                          (index) {
                            final percentage = (speciesList[index].value / totalTrees * 100).toStringAsFixed(1);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: colors[index % colors.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${speciesList[index].key}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Species list
          const Text(
            'Trees by Species',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: speciesList.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final species = speciesList[index];
                final percentage = (species.value / totalTrees * 100).toStringAsFixed(1);
                
                return ListTile(
                  title: Text(
                    species.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: LinearProgressIndicator(
                    value: species.value / totalTrees,
                    backgroundColor: colors[index % colors.length].withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colors[index % colors.length]),
                  ),
                  trailing: Text(
                    '${species.value} trees\n$percentage%',
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTeamTab(BuildContext context, List<Tree> trees) {
    // Group trees by team
    final teamMap = <String, int>{};
    for (var tree in trees) {
      final team = tree.teamName ?? 'Unassigned';
      teamMap[team] = (teamMap[team] ?? 0) + tree.quantity;
    }
      final teamList = teamMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // We only need maxValue for calculating percentage, totalTrees not used here
    final maxValue = teamList.isNotEmpty ? teamList.first.value : 0;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Team rankings
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: teamList.map((team) {
                  final percentage = (team.value / maxValue);
                  final barColor = team.key == 'PMI Nairobi Team' ? 
                    Theme.of(context).colorScheme.primary :
                    Theme.of(context).colorScheme.secondary;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                team.key,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${team.value} trees',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            Container(
                              height: 8,
                              width: MediaQuery.of(context).size.width * 0.8 * percentage,
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Team contributions
          const Text(
            'Team Contributions by Month',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 220,
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Coming soon',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Center(
                        child: Icon(
                          Icons.bar_chart,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],      ),
    );
  }
  
  Widget _buildCarbonCreditsTab(BuildContext context, List<Tree> trees) {
    // Carbon credit calculations
    final totalTrees = trees.fold(0, (sum, tree) => sum + tree.quantity);
    
    // Average CO2 absorption rates per tree (kg/year) by species
    const carbonAbsorptionRates = {
      'Acacia': 21.8,
      'Eucalyptus': 35.3,
      'Pine': 13.0,
      'Mango': 28.5,
      'Baobab': 32.7,
      'Oak': 22.0,
      'Cypress': 17.5,
      'Bamboo': 12.0,
      'Cedar': 25.4,
      'Mahogany': 30.2,
    };
    
    // Calculate CO2 absorbed by species
    final speciesCarbonMap = <String, double>{};
    double totalCarbonAbsorbed = 0;
    
    for (var tree in trees) {
      final species = tree.species;
      final rate = carbonAbsorptionRates[species] ?? 22.0; // Default rate if species not found
      final yearsGrown = DateTime.now().difference(tree.plantingDate).inDays / 365;
      final carbonPerTree = rate * yearsGrown.clamp(0.1, double.infinity); // Minimum 0.1 year
      final totalCarbon = carbonPerTree * tree.quantity;
      
      speciesCarbonMap[species] = (speciesCarbonMap[species] ?? 0) + totalCarbon;
      totalCarbonAbsorbed += totalCarbon;
    }
    
    // Convert to carbon credits (1 credit = 1 metric ton CO2)
    final totalCarbonCredits = totalCarbonAbsorbed / 1000;
    final estimatedValue = totalCarbonCredits * 15; // $15 per credit (average market price)
    
    // Sort species by carbon contribution
    final sortedSpecies = speciesCarbonMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cards with key metrics
          Row(
            children: [
              _buildCarbonStatCard(
                context,
                title: 'CO₂ Absorbed',
                value: '${totalCarbonAbsorbed.toStringAsFixed(1)} kg',
                icon: Icons.eco,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              _buildCarbonStatCard(
                context,
                title: 'Carbon Credits',
                value: totalCarbonCredits.toStringAsFixed(2),
                icon: Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCarbonStatCard(
                context,
                title: 'Estimated Value',
                value: '\$${estimatedValue.toStringAsFixed(0)}',
                icon: Icons.monetization_on,
                color: const Color(0xFF00AEEF), // PMI Blue
              ),
              const SizedBox(width: 16),
              _buildCarbonStatCard(
                context,
                title: 'Average/Tree',
                value: '${(totalCarbonAbsorbed / totalTrees).toStringAsFixed(1)} kg',
                icon: Icons.trending_up,
                color: const Color(0xFF662D91), // Purple
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Carbon impact explanation
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Carbon Credit Impact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Carbon credits represent the amount of CO₂ your trees have absorbed from the atmosphere. Each credit equals 1 metric ton (1,000 kg) of CO₂ removed.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This environmental impact contributes to climate change mitigation and can generate revenue through carbon credit markets.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Species contribution breakdown
          const Text(
            'CO₂ Absorption by Species',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sortedSpecies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final species = sortedSpecies[index];
                final percentage = (species.value / totalCarbonAbsorbed * 100).toStringAsFixed(1);
                final credits = (species.value / 1000).toStringAsFixed(3);
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    child: Icon(
                      Icons.eco,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    species.key,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${species.value.toStringAsFixed(1)} kg CO₂'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: species.value / totalCarbonAbsorbed,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$credits credits',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$percentage%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Monthly carbon absorption trend
          const Text(
            'Monthly Carbon Absorption Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Carbon absorption increases over time as trees grow larger and more efficient at CO₂ sequestration.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),                  SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Growing Impact',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCarbonStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

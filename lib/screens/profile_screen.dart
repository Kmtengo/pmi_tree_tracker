import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_view_model.dart';
import '../view_models/tree_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editMode = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userViewModel = Provider.of<UserViewModel>(context, listen: false);
      if (userViewModel.currentUser != null) {
        _nameController.text = userViewModel.currentUser!.name;
        _emailController.text = userViewModel.currentUser!.email;
        _phoneController.text = userViewModel.currentUser!.phone ?? '';
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  void _toggleEditMode() {
    setState(() {
      _editMode = !_editMode;
      
      // Reset controllers to current values if canceling edit
      if (!_editMode) {
        final userViewModel = Provider.of<UserViewModel>(context, listen: false);
        if (userViewModel.currentUser != null) {
          _nameController.text = userViewModel.currentUser!.name;
          _emailController.text = userViewModel.currentUser!.email;
          _phoneController.text = userViewModel.currentUser!.phone ?? '';
        }
      }
    });
  }
  
  Future<void> _saveProfile() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    final success = await userViewModel.updateUserProfile(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
    );
    
    if (success) {
      setState(() {
        _editMode = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${userViewModel.error ?? 'Could not update profile'}')),
      );
    }
  }
    Future<void> _logout() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await userViewModel.logout();
              },
              child: const Text('LOGOUT'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _synchronizeData() async {
    final treeViewModel = Provider.of<TreeViewModel>(context, listen: false);
    
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Synchronizing'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Synchronizing data with the cloud...'),
            ],
          ),
        );
      },
    );
    
    try {
      // Attempt synchronization
      bool result = await treeViewModel.synchronizeWithDataverse();
      
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result 
            ? 'Data synchronized successfully!' 
            : 'Failed to synchronize data'),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserViewModel>(
        builder: (context, userViewModel, child) {
          if (userViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (userViewModel.currentUser == null) {
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
                  const Text('User not found'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => userViewModel.logout(),
                    child: const Text('Return to Login'),
                  ),
                ],
              ),
            );
          }
          
          final user = userViewModel.currentUser!;
          final role = user.role ?? 'Member';
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      role,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context, 
                                title: 'Trees Planted', 
                                value: '215',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStatCard(
                                context, 
                                title: 'Projects', 
                                value: '4',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Profile details
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Profile Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _editMode ? Icons.cancel : Icons.edit,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: _toggleEditMode,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        if (_editMode) ...[
                          // Edit mode
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Save Changes'),
                            ),
                          ),
                        ] else ...[
                          // Display mode
                          _buildProfileField(
                            context, 
                            label: 'Name', 
                            value: user.name,
                            icon: Icons.person,
                          ),
                          const Divider(),
                          _buildProfileField(
                            context, 
                            label: 'Email', 
                            value: user.email,
                            icon: Icons.email,
                          ),
                          const Divider(),
                          _buildProfileField(
                            context, 
                            label: 'Phone', 
                            value: user.phone ?? 'Not set',
                            icon: Icons.phone,
                          ),
                          const Divider(),
                          _buildProfileField(
                            context, 
                            label: 'Team', 
                            value: user.team ?? 'Not assigned',
                            icon: Icons.group,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Settings
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsItem(
                          context,
                          title: 'Notifications',
                          icon: Icons.notifications,
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(),
                        _buildSettingsItem(
                          context,
                          title: 'Dark Mode',
                          icon: Icons.dark_mode,
                          trailing: Switch(
                            value: false,
                            onChanged: (value) {},
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(),
                        _buildSettingsItem(
                          context,
                          title: 'Location Services',
                          icon: Icons.location_on,
                          trailing: Switch(
                            value: true,
                            onChanged: (value) {},
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(),
                        _buildSettingsItem(
                          context,
                          title: 'Change Password',
                          icon: Icons.lock,
                          onTap: () {
                            // Show change password dialog
                          },
                        ),                        const Divider(),
                        _buildSettingsItem(
                          context,
                          title: 'Synchronize Data',
                          icon: Icons.sync,
                          onTap: _synchronizeData,
                        ),
                        const Divider(),
                        _buildSettingsItem(
                          context,
                          title: 'Logout',
                          icon: Icons.exit_to_app,
                          onTap: _logout,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildStatCard(BuildContext context, {required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingsItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

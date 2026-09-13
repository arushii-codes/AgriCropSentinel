import 'package:flutter/material.dart';
import 'package:farmer_app/services/api_service.dart';
import 'package:farmer_app/services/storage_service.dart';
import 'package:farmer_app/screens/homepage.dart';
import 'package:farmer_app/screens/login.dart';
// import 'package:farmer_app/widgets/login_popup.dart';
// import 'package:farmer_app/screens/market_home.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

// ... imports remain the same

class _ProfilePageState extends State<ProfilePage> {
  String? userName;
  String? userPhone;
  bool isLoading = true;
  bool isLoggedIn = false; // Track login state
  // int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final token = await StorageService.getToken();
    if (token != null) {
      // User is logged in, fetch profile
      setState(() {
        isLoggedIn = true;
      });
      fetchProfile();
    } else {
      // Not logged in
      setState(() {
        isLoggedIn = false;
        isLoading = false;
      });
    }
  }

  Future<void> fetchProfile() async {
    try {
      final profile = await ApiService.getUserProfile();
      setState(() {
        userName = profile['name'] ?? "Unknown";
        userPhone = profile['phone'] ?? "N/A";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        userName = "Error";
        userPhone = "";
        isLoading = false;
      });
    }
  }

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  // void _handleAccountTap(BuildContext context) async {
  //   final loggedIn = await StorageService.isLoggedIn();
  //   if (loggedIn) {
  //     // User is already logged in → go directly to ProfilePage
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(builder: (_) => const CropDropApp()),
  //     );
  //   } else {
  //     // User is not logged in → show login popup
  //     await LoginPopup.show(context);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2E7D32);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Back button + Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Text(
                    'Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(
                        Icons.person_outline,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Username & Phone (only if logged in)
                    if (isLoggedIn)
                      isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                Text(
                                  userName ?? "No Name",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userPhone != null && userPhone!.isNotEmpty
                                      ? "+91 ${userPhone!}"
                                      : "No Phone",
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),

                    // If not logged in, show login prompt
                    if (!isLoggedIn && !isLoading) ...[
                      const Text(
                        'You are not logged in',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Menu Items (always visible)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          ProfileMenuItem(
                            icon: Icons.edit_outlined,
                            title: 'Edit Profile',
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Edit Profile feature coming soon..!',
                                  ),
                                ),
                              );
                            },
                          ),
                          ProfileMenuItem(
                            icon: Icons.settings,
                            title: 'Settings',
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Settings feature coming soon..!',
                                  ),
                                ),
                              );
                            },
                          ),
                          ProfileMenuItem(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Help & Support feature coming soon..!',
                                  ),
                                ),
                              );
                            },
                          ),
                          ProfileMenuItem(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Order History',
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Order History feature coming soon..!',
                                  ),
                                ),
                              );
                            },
                          ),
                          ProfileMenuItem(
                            icon: Icons.payments_outlined,
                            title: 'Wallet/Payment Details',
                            color: primaryColor,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Wallet/Payment Details feature coming soon..!',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Logout button at bottom (only if logged in)
            if (isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ProfileMenuItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  color: Colors.red,
                  onTap: () async {
                    await StorageService.removeToken();
                    setState(() {
                      isLoggedIn = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CropDropApp(),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      // bottomNavigationBar: BottomNavigationBar(
      //   backgroundColor: Colors.white,
      //   items: [
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.home_outlined), // Always green
      //       label: 'Home',
      //     ),
      //     const BottomNavigationBarItem(
      //       icon: Icon(Icons.eco_outlined),
      //       label: 'My Crops',
      //     ),
      //     const BottomNavigationBarItem(
      //       icon: Icon(Icons.shopping_bag_outlined),
      //       label: 'Market',
      //     ),
      //     const BottomNavigationBarItem(
      //       icon: Icon(Icons.bar_chart),
      //       label: 'NPK',
      //     ),
      //     const BottomNavigationBarItem(
      //       icon: Icon(Icons.person),
      //       label: 'Account',
      //     ),
      //   ],
      //   // 👇 Ab ye values matter nahi karti
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: Color(0xFF2E7D32),
      //   unselectedItemColor: Colors.grey,
      //   showUnselectedLabels: true,
      //   type: BottomNavigationBarType.fixed,
      //   elevation: 2,

      //   onTap: (int index) async {
      //     if (index == 1) {
      //       _handleAccountTap(context);
      //     } else if (index == 0) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => const CropDropApp()),
      //       );
      //     } else if (index == 2) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => const GroceryApp()),
      //       );
      //     } else if (index == 4) {
      //       Navigator.push(
      //         context,
      //         MaterialPageRoute(builder: (context) => const ProfilePage()),
      //       );
      //     } else {
      //       _onItemTapped(index);
      //     }
      //   },
      // ),
    );
  }
}

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: icon == Icons.logout ? Colors.red : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}

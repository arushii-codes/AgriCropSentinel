import 'package:farmer_app/screens/login.dart';
import 'package:flutter/material.dart';
//import 'package:farmer_app/screens/profile_page.dart';
import 'package:farmer_app/services/storage_service.dart';

class LoginPopup {
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color lightGreenColor = Color(0xFFD4EAD5);

  /// Show login dialog only if user is not logged in
  static Future<void> show(BuildContext context) async {
    final loggedIn = await StorageService.isLoggedIn();
    if (loggedIn) return; // Already logged in, don't show popup

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Login Required',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (_, anim1, __, ___) {
        final curvedValue = Curves.easeOutBack.transform(anim1.value);
        return Transform.scale(
          scale: curvedValue,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _DialogContent(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DialogContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Login Required',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        const SizedBox(height: 16),
        Text(
          'You need to log in to continue and access all features.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // Login button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              // Here, you could navigate to a dedicated login screen
              Navigator.of(context).pop(); // Close popup first
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LoginPopup.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Login', style: TextStyle(fontSize: 16)),
          ),
        ),
        const SizedBox(height: 12),

        // Maybe Later button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: LoginPopup.lightGreenColor,
              foregroundColor: LoginPopup.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Maybe Later', style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

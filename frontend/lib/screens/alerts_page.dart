import 'package:flutter/material.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crop Alerts"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _alertCard(
            context,
            icon: Icons.warning_amber_rounded,
            title: "Weather Alert",
            message:
                "High humidity may increase the risk of fungal disease.",
            severity: "Medium Risk",
          ),
          const SizedBox(height: 12),
          _alertCard(
            context,
            icon: Icons.bug_report_outlined,
            title: "Pest Alert",
            message:
                "Nearby pest cases have been reported. Monitor your crop regularly.",
            severity: "Medium Risk",
          ),
          const SizedBox(height: 12),
          _alertCard(
            context,
            icon: Icons.water_drop_outlined,
            title: "Crop Advisory",
            message:
                "Avoid excessive irrigation during periods of high humidity.",
            severity: "Low Risk",
          ),
          const SizedBox(height: 12),
          _alertCard(
            context,
            icon: Icons.eco_outlined,
            title: "Crop Monitoring",
            message:
                "Regularly inspect leaves for spots, discoloration and pest damage.",
            severity: "Monitor",
          ),
        ],
      ),
    );
  }

  Widget _alertCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required String severity,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    severity,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
}
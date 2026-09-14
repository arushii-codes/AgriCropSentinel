import 'package:flutter/material.dart';

class OfficerDashboard extends StatelessWidget {
  const OfficerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Officer Dashboard"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Crop Health Overview",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Monitor crop disease and pest risk in the region.",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    "12",
                    "Active Cases",
                    Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    "7",
                    "High Risk",
                    Icons.dangerous_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                    context,
                    "24",
                    "Farmers",
                    Icons.people_outline,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    context,
                    "5",
                    "Alerts",
                    Icons.notifications_none,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              "Recent Risk Reports",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _riskReport(
              context,
              "Tomato",
              "Late Blight",
              "High",
              Icons.eco_outlined,
            ),

            _riskReport(
              context,
              "Wheat",
              "Rust",
              "Medium",
              Icons.grass_outlined,
            ),

            _riskReport(
              context,
              "Rice",
              "Pest Activity",
              "Medium",
              Icons.agriculture_outlined,
            ),

            _riskReport(
              context,
              "Cotton",
              "Leaf Spot",
              "Low",
              Icons.local_florist_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context,
    String number,
    String title,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 30,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              number,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title),
          ],
        ),
      ),
    );
  }

  Widget _riskReport(
    BuildContext context,
    String crop,
    String disease,
    String risk,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(
          crop,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(disease),
        trailing: Text(
          risk,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set status bar icons to be dark, as the top background is light
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return MaterialApp(debugShowCheckedModeBanner: false, home: WeatherAppUI());
  }
}

class WeatherAppUI extends StatelessWidget {
  const WeatherAppUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This dark color will be the background for the bottom section
      backgroundColor: const Color(0xFF333333),
      body: SingleChildScrollView(
        child: Column(children: [_buildTopSection(), _buildBottomSection()]),
      ),
    );
  }

  /// Builds the top container with the gradient and current weather info
  Widget _buildTopSection() {
    return Container(
      decoration: BoxDecoration(
        // Gradient matching the image (yellowish to light blue/grey)
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFF9D48A), // Light sunny yellow
            const Color(0xFFB0C8D6), // Muted blue/grey
          ],
        ),
        // This creates the large curve at the bottom
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        // Ensures content isn't under the status bar, but only for the top
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Custom App Bar (Row)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.add, color: Colors.black, size: 28),
                  const Text(
                    "Milan",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Icon(Icons.menu, color: Colors.black, size: 28),
                ],
              ),
              const SizedBox(height: 15),

              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 30),

              // Main Temperature
              const Text(
                "24°C",
                style: TextStyle(
                  fontSize: 90,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // Weather Icon (Placeholder)
              const Icon(
                Icons.wb_sunny_outlined, // Placeholder for the sun icon
                color: Colors.black,
                size: 35,
              ),
              const SizedBox(height: 10),

              // Weather Condition
              const Text(
                "Sunny",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),

              // High / Low Temp
              const Text(
                "32° / 24°",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),

              // Details Row (Humidity, Wind, Precipitation)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    icon: Icons.water_drop_outlined, // Humidity icon
                    title: "Humidity",
                    value: "51%",
                  ),
                  _buildDetailItem(
                    icon: Icons.air, // Wind icon
                    title: "Wind now",
                    value: "10km",
                  ),
                  _buildDetailItem(
                    icon: Icons.umbrella_outlined, // Precipitation icon
                    title: "Precipitation",
                    value: "4%",
                  ),
                ],
              ),
              const SizedBox(height: 30), // Padding for the curve
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the bottom container with the 3-day forecast
  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "3-day forecast",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildForecastItem(
                temp: "26° / 15°",
                icon: Icons.cloud_outlined, // Placeholder
                day: "Mon",
                date: "24.09",
              ),
              _buildForecastItem(
                temp: "33° / 20°",
                icon: Icons.wb_sunny_outlined, // Placeholder
                day: "Tue",
                date: "25.09",
              ),
              _buildForecastItem(
                temp: "23° / 14°",
                icon: Icons.grain, // Placeholder for rain
                day: "Wed",
                date: "26.09",
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper widget for the detail items (Humidity, Wind, etc.)
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.black.withOpacity(0.7), size: 28),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  /// Helper widget for the 3-day forecast items
  Widget _buildForecastItem({
    required String temp,
    required IconData icon,
    required String day,
    required String date,
  }) {
    return Column(
      children: [
        Text(
          temp,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 10),
        Text(
          day,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

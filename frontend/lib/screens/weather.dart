//import 'package:farmer_app/screens/homepage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:farmer_app/services/weather_service.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const WeatherHomePage();
  }
}

// ------------------ Models ------------------
class HourlyForecast {
  final String time;
  final IconData icon;
  final String temperature;
  final bool isSelected;

  HourlyForecast({
    required this.time,
    required this.icon,
    required this.temperature,
    this.isSelected = false,
  });
}

class DailyForecast {
  final String day;
  final IconData icon;
  final String condition;
  final String tempHigh;
  final String tempLow;

  DailyForecast({
    required this.day,
    required this.icon,
    required this.condition,
    required this.tempHigh,
    required this.tempLow,
  });
}

// ------------------ Dummy Data ------------------
final List<HourlyForecast> hourlyForecasts = [
  HourlyForecast(
    time: "10:00",
    icon: CupertinoIcons.cloud_sun,
    temperature: "23°",
  ),
  HourlyForecast(
    time: "11:00",
    icon: CupertinoIcons.cloud_bolt_rain,
    temperature: "21°",
    isSelected: true,
  ),
  HourlyForecast(
    time: "12:00",
    icon: CupertinoIcons.cloud_heavyrain,
    temperature: "22°",
  ),
  HourlyForecast(time: "14:00", icon: CupertinoIcons.cloud, temperature: "19°"),
  HourlyForecast(time: "15:00", icon: CupertinoIcons.cloud, temperature: "19°"),
  HourlyForecast(time: "16:00", icon: CupertinoIcons.cloud, temperature: "19°"),
];

final List<DailyForecast> dailyForecasts = [
  DailyForecast(
    day: "Mon",
    icon: CupertinoIcons.cloud_sun,
    condition: "Sunny",
    tempHigh: "25",
    tempLow: "18",
  ),
  DailyForecast(
    day: "Tue",
    icon: CupertinoIcons.cloud_rain,
    condition: "Rainy",
    tempHigh: "22",
    tempLow: "17",
  ),
  DailyForecast(
    day: "Wed",
    icon: CupertinoIcons.cloud,
    condition: "Cloudy",
    tempHigh: "24",
    tempLow: "19",
  ),
  DailyForecast(
    day: "Thu",
    icon: CupertinoIcons.cloud_snow,
    condition: "Snow",
    tempHigh: "18",
    tempLow: "12",
  ),
  DailyForecast(
    day: "Fri",
    icon: CupertinoIcons.cloud_bolt,
    condition: "Storm",
    tempHigh: "20",
    tempLow: "15",
  ),
];

// ------------------ Home Screen ------------------
class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String city = "Loading...";
  String temperature = "--";
  String condition = "Loading...";
  String humidity = "--";
  String windSpeed = "--";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWeather();
  }

  Future<void> loadWeather() async {
    try {
      final position = await getUserLocation();
      final data = await fetchWeather(position.latitude, position.longitude);

      // Get city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String cityName = placemarks.isNotEmpty
          ? placemarks.first.locality ?? "Unknown"
          : "Unknown";

      setState(() {
        city = cityName;
        temperature = data["main"]["temp"].toStringAsFixed(0);
        condition = data["weather"][0]["main"];
        humidity = data["main"]["humidity"].toString();
        windSpeed = data["wind"]["speed"].toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        city = "Error fetching";
        isLoading = false;
      });
      print("Error loading weather: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              _CustomAppBar(city: city),
              const SizedBox(height: 15),
              _MainWeatherInfo(
                temperature: temperature,
                condition: condition,
                humidity: humidity,
                windSpeed: windSpeed,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  child: Column(
                    children: [_buildHeader(context), _buildHourlyForecast()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today",
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SevenDayForecastPage()),
            );
          },
          child: const Text(
            "7 Days >",
            style: TextStyle(
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyForecasts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final forecast = hourlyForecasts[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: 80,
            decoration: BoxDecoration(
              color: forecast.isSelected
                  ? const Color(0xFF2E7D32).withOpacity(0.2)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: forecast.isSelected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF2E7D32).withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  forecast.time,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(forecast.icon, color: const Color(0xFF2E7D32), size: 28),
                const SizedBox(height: 6),
                Text(
                  forecast.temperature,
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ------------------ Custom AppBar ------------------
class _CustomAppBar extends StatelessWidget {
  final String city;
  const _CustomAppBar({required this.city});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF2E7D32),
              size: 28,
            ),
          ),
          Column(
            children: [
              Text(
                city,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Live Weather",
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
            ],
          ),
          const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 28),
        ],
      ),
    );
  }
}

// ------------------ Main Weather Info ------------------
class _MainWeatherInfo extends StatelessWidget {
  final String temperature;
  final String condition;
  final String humidity;
  final String windSpeed;

  const _MainWeatherInfo({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
  });

  String getWeatherIcon(String condition) {
    final description = condition.toLowerCase();
    final currentHour = DateTime.now().hour;
    bool isDayTime = currentHour >= 6 && currentHour < 18;

    if (description.contains('cloud')) {
      return 'assets/cloud.png';
    } else if (description.contains('sun') || description.contains('clear')) {
      return isDayTime ? 'assets/sun.png' : 'assets/moon3.png';
    } else if (description.contains('rain') ||
        description.contains('drizzle')) {
      return 'assets/rain.png';
    } else if (description.contains('storm') ||
        description.contains('thunder')) {
      return 'assets/thunder.png';
    } else {
      return isDayTime ? 'assets/sun.png' : 'assets/moon3.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(getWeatherIcon(condition), width: 150, height: 150),
        const SizedBox(height: 8),
        Text(
          '$temperature°c',
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 90,
            fontWeight: FontWeight.w200,
          ),
        ),
        Text(
          condition,
          style: const TextStyle(
            color: Color(0xFF2E7D32),
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _WeatherDetail(
              icon: Icons.air,
              value: "$windSpeed km/h",
              label: "Wind",
              color: Colors.grey,
            ),
            _WeatherDetail(
              icon: Icons.water_drop,
              value: "$humidity%",
              label: "Humidity",
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------ Weather Detail ------------------
class _WeatherDetail extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _WeatherDetail({
    required this.icon,
    required this.value,
    required this.label,
    this.color = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 18)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 18)),
      ],
    );
  }
}

// ------------------ 7-Day Forecast ------------------
class SevenDayForecastPage extends StatelessWidget {
  const SevenDayForecastPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "7-Day Forecast",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF81C784)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(top: 120),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(35),
              topRight: Radius.circular(35),
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            itemCount: dailyForecasts.length,
            itemBuilder: (context, index) {
              final forecast = dailyForecasts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF2E7D32).withOpacity(0.1),
                      child: Icon(
                        forecast.icon,
                        color: const Color(0xFF2E7D32),
                        size: 28,
                      ),
                    ),
                    title: Text(
                      forecast.day,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    subtitle: Text(
                      forecast.condition,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Text(
                      "${forecast.tempHigh}° / ${forecast.tempLow}°",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

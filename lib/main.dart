import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_icons/weather_icons.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WeatherPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String _weatherData = '';
  String _locationName = '';
  bool _isLoading = false;
  bool _hasError = false;
  List<dynamic> _forecastData = [];
  TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeatherDataFromLocation();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeatherDataFromLocation() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _weatherData = 'Location permission denied';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final locationName =
          await _fetchLocationName(position.latitude, position.longitude);

      final apiKey = '9ac983a365eaf250d5c38fc21578451f';
      final weatherUrl =
          'http://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';

      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      if (weatherResponse.statusCode == 200) {
        final weatherData = json.decode(weatherResponse.body);
        final weatherDescription = weatherData['weather'][0]['description'];
        final temperature = weatherData['main']['temp'];
        final humidity = weatherData['main']['humidity'];
        final windSpeed = weatherData['wind']['speed'];
        final pressure = weatherData['main']['pressure'];
        final uvIndex = await _fetchUVIndex(position.latitude, position.longitude);
        final forecastData = await _fetchWeatherForecast(position.latitude, position.longitude);

        setState(() {
          _isLoading = false;
          _weatherData =
              'Weather: $weatherDescription\nTemperature: $temperature°C\nHumidity: $humidity%\nUV Index: $uvIndex\nWind Speed: $windSpeed m/s\nPressure: $pressure hPa';
          _locationName = locationName;
          _forecastData = forecastData;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _weatherData = 'Failed to load weather data';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _weatherData = 'Error fetching weather data: $error';
      });
    }
  }

  Future<String> _fetchLocationName(double latitude, double longitude) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&zoom=10';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final address = jsonData['display_name'];
      return address;
    } else {
      return 'Unknown';
    }
  }

  Future<String> _fetchUVIndex(double latitude, double longitude) async {
    final openUVApiKey = '9ac983a365eaf250d5c38fc21578451f';
    final uvUrl = 'https://api.openuv.io/api/v1/uv?lat=$latitude&lng=$longitude';
    final uvResponse = await http.get(
      Uri.parse(uvUrl),
      headers: {'x-access-token': openUVApiKey},
    );
    if (uvResponse.statusCode == 200) {
      final uvData = json.decode(uvResponse.body);
      final uvIndex = uvData['result']['uv'];
      return uvIndex.toString();
    } else {
      return 'Unknown';
    }
  }

  Future<List<dynamic>> _fetchWeatherForecast(double latitude, double longitude) async {
    final apiKey = '9ac983a365eaf250d5c38fc21578451f';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/onecall?lat=$latitude&lon=$longitude&exclude=current,minutely,hourly,alerts&appid=$apiKey&units=metric';

    final forecastResponse = await http.get(Uri.parse(forecastUrl));
    if (forecastResponse.statusCode == 200) {
      final forecastData = json.decode(forecastResponse.body);
      return forecastData['daily'];
    } else {
      return [];
    }
  }

  Future<void> _fetchWeatherDataFromCity(String cityName) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final apiKey = '9ac983a365eaf250d5c38fc21578451f';
      final url =
          'http://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        final weatherDescription = weatherData['weather'][0]['description'];
        final temperature = weatherData['main']['temp'];
        final humidity = weatherData['main']['humidity'];
        final windSpeed = weatherData['wind']['speed'];
        final pressure = weatherData['main']['pressure'];

        final forecastData = await _fetchWeatherForecast(
            weatherData['coord']['lat'], weatherData['coord']['lon']);

        setState(() {
          _isLoading = false;
          _weatherData =
              'Weather: $weatherDescription\nTemperature: $temperature°C\nHumidity: $humidity%\nWind Speed: $windSpeed m/s\nPressure: $pressure hPa';
          _locationName = cityName;
          _forecastData = forecastData;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _weatherData = 'Failed to load weather data';
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _weatherData = 'Error fetching weather data: $error';
      });
    }
  }

  Icon _getWeatherIcon(String weatherData) {
    String weatherLowerCase = weatherData.toLowerCase();
    if (weatherLowerCase.contains('haze')) {
      return Icon(WeatherIcons.fog);
    } else if (weatherLowerCase.contains('cloud')) {
      return Icon(WeatherIcons.cloud);
    } else if (weatherLowerCase.contains('rain')) {
      return Icon(WeatherIcons.rain);
    } else if (weatherLowerCase.contains('snow')) {
      return Icon(WeatherIcons.snow);
    } else if (weatherLowerCase.contains('clear')) {
      return Icon(WeatherIcons.sunrise);
    } else {
      return Icon(WeatherIcons.day_sunny);
    }
  }

  Widget _buildWeatherIcon(dynamic dayForecast) {
    String weatherDescription = dayForecast['weather'][0]['description'].toLowerCase();
    if (weatherDescription.contains('haze')) {
      return Icon(WeatherIcons.fog);
    } else if (weatherDescription.contains('cloud')) {
      return Icon(WeatherIcons.cloud);
    } else if (weatherDescription.contains('rain')) {
      return Icon(WeatherIcons.rain);
    } else if (weatherDescription.contains('snow')) {
      return Icon(WeatherIcons.snow);
    } else if (weatherDescription.contains('clear')) {
      return Icon(WeatherIcons.day_sunny);
    } else {
      return Icon(WeatherIcons.sunrise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchWeatherDataFromLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'Enter City Name',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    String cityName = _cityController.text.trim();
                    if (cityName.isNotEmpty) {
                      _fetchWeatherDataFromCity(cityName);
                    }
                  },
                  child: Text('Search'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: _isLoading
                  ? CircularProgressIndicator()
                  : _hasError
                      ? Text(_weatherData)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _getWeatherIcon(_weatherData),
                                SizedBox(width: 10),
                                Text(_weatherData),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text('Location: $_locationName'),
                            SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _forecastData.length,
                                itemBuilder: (context, index) {
                                  final dayForecast = _forecastData[index];
                                  final date = DateTime.fromMillisecondsSinceEpoch(
                                      dayForecast['dt'] * 1000);
                                  final weather = dayForecast['weather'][0]['description'];
                                  final temp = dayForecast['temp']['day'];

                                  return ListTile(
                                    title: Text('${date.day}/${date.month}/${date.year}'),
                                    subtitle: Text('Weather: $weather, Temp: ${temp}°C'),
                                    leading: _buildWeatherIcon(dayForecast),
                                  );
                                },
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
}

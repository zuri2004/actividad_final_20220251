import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Movie {
  final String title;
  final String overview;
  final String releaseDate;
  final double rating;
  final String? posterPath; // URL de la portada de la película

  Movie({
    required this.title,
    required this.overview,
    required this.releaseDate,
    required this.rating,
    required this.posterPath,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'],
      overview: json['overview'],
      releaseDate: json['release_date'],
      rating: (json['vote_average'] ?? 0.0).toDouble(),
      posterPath: json['poster_path'], // URL de la portada de la película
    );
  }
}

class FilterCriteria {
  String title = '';
  String year = '';
  String rating = '';
}

class FilterScreen extends StatefulWidget {
  final FilterCriteria filterCriteria;

  const FilterScreen({Key? key, required this.filterCriteria})
      : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late TextEditingController _titleController;
  late TextEditingController _yearController;
  late TextEditingController _ratingController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.filterCriteria.title);
    _yearController = TextEditingController(text: widget.filterCriteria.year);
    _ratingController =
        TextEditingController(text: widget.filterCriteria.rating);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Filter Criteria'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: InputDecoration(labelText: 'Year'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _ratingController,
              decoration: InputDecoration(labelText: 'Rating'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                widget.filterCriteria.title = _titleController.text;
                widget.filterCriteria.year = _yearController.text;
                widget.filterCriteria.rating = _ratingController.text;
                Navigator.pop(context, widget.filterCriteria);
              },
              child: Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class PopularM extends StatefulWidget {
  const PopularM({Key? key}) : super(key: key);

  @override
  _PopularMState createState() => _PopularMState();
}

class _PopularMState extends State<PopularM> {
  late Future<List<Movie>> futurepopular;
  FilterCriteria filterCriteria = FilterCriteria();

  @override
  void initState() {
    super.initState();
    futurepopular = fetchpopular();
  }

  Future<List<Movie>> fetchpopular() async {
    final response = await http.get(
      Uri.parse(
          'https://api.themoviedb.org/3/movie/popular?api_key=58c207bd5cc2dd27d2fa1429c5dfade7&language=en-US&page=1'),
    );

    if (response.statusCode == 200) {
      final List<Movie> movies = [];
      final Map<String, dynamic> jsonData = json.decode(response.body);
      final List<dynamic> results = jsonData['results'];
      results.forEach((movieData) {
        final Movie movie = Movie.fromJson(movieData);
        movies.add(movie);
      });
      return movies;
    } else {
      throw Exception('Failed to load movies');
    }
  }

  List<Movie> _filterMovies(List<Movie> movies) {
    String title = filterCriteria.title.toLowerCase();
    String year = filterCriteria.year.toLowerCase();
    String rating = filterCriteria.rating;

    return movies.where((movie) {
      bool matchesTitle = movie.title.toLowerCase().contains(title);
      bool matchesYear = movie.releaseDate.contains(year);
      bool matchesRating = movie.rating.toString().contains(rating);
      return matchesTitle && matchesYear && matchesRating;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Popular Movies'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Movie>>(
              future: futurepopular,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  List<Movie> filteredMovies =
                      _filterMovies(snapshot.data ?? []);
                  return ListView.builder(
                    itemCount: filteredMovies.length,
                    itemBuilder: (context, index) {
                      final movie = filteredMovies[index];
                      return Card(
                        margin: EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: movie.posterPath != null
                              ? Image.network(
                                  'https://image.tmdb.org/t/p/w185${movie.posterPath}',
                                  width: 50,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Container(), // imagen de la portada de la película si está disponible
                          title: Text(movie.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Release Date: ${movie.releaseDate}'),
                              Text('Overview: ${movie.overview}'),
                              Text('Rating: ${movie.rating}'),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                FilterCriteria newFilterCriteria = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FilterScreen(filterCriteria: filterCriteria),
                  ),
                );
                if (newFilterCriteria != null) {
                  setState(() {
                    filterCriteria = newFilterCriteria;
                  });
                }
              },
              child: Text('Filter'),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: PopularM(),
  ));
}

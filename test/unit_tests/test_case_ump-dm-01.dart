// UMM-DM-01: Student can view the motivational quotes on the home page
// Requirement: Students can view inspiring motivational quotes displayed on their home page
// Mirrors logic in `student_home.dart` (display motivational quotes with proper loading and error handling)

import 'package:flutter_test/flutter_test.dart';

// Mock class to represent a motivational quote
class MockMotivationalQuote {
  final int id;
  final String quote;
  final String author;
  final String category;
  final bool isActive;
  final DateTime createdAt;

  MockMotivationalQuote({
    required this.id,
    required this.quote,
    required this.author,
    required this.category,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quote': quote,
      'author': author,
      'category': category,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory MockMotivationalQuote.fromMap(Map<String, dynamic> map) {
    return MockMotivationalQuote(
      id: map['id'],
      quote: map['quote'],
      author: map['author'],
      category: map['category'],
      isActive: map['is_active'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

// Mock database class to simulate Supabase operations
class MockDatabase {
  List<Map<String, dynamic>> _motivationalQuotes = [];
  bool _shouldThrowError = false;

  void seedMotivationalQuotes(List<Map<String, dynamic>> quotes) {
    _motivationalQuotes = quotes;
  }

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  Future<List<Map<String, dynamic>>> fetchActiveMotivationalQuotes() async {
    // Simulate network delay
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    return _motivationalQuotes
        .where((quote) => quote['is_active'] == true)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchMotivationalQuotesByCategory(String category) async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    return _motivationalQuotes
        .where((quote) => quote['is_active'] == true && quote['category'] == category)
        .toList();
  }

  Future<Map<String, dynamic>?> fetchRandomMotivationalQuote() async {
    await Future.delayed(Duration(milliseconds: 100));
    
    if (_shouldThrowError) {
      throw Exception('Database connection failed');
    }
    
    final activeQuotes = _motivationalQuotes
        .where((quote) => quote['is_active'] == true)
        .toList();
    
    if (activeQuotes.isEmpty) {
      return null;
    }
    
    // Return first quote for predictable testing
    return activeQuotes.first;
  }
}

// Service class to handle motivational quotes display
class MotivationalQuotesService {
  final MockDatabase _database;
  List<MockMotivationalQuote> _quotes = [];
  MockMotivationalQuote? _dailyQuote;
  bool _isLoading = false;
  String? _errorMessage;

  MotivationalQuotesService(this._database);

  List<MockMotivationalQuote> get quotes => _quotes;
  MockMotivationalQuote? get dailyQuote => _dailyQuote;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMotivationalQuotes() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final quotesData = await _database.fetchActiveMotivationalQuotes();
      _quotes = quotesData.map((data) => MockMotivationalQuote.fromMap(data)).toList();
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load motivational quotes: ${e.toString()}';
      _quotes = [];
    }
  }

  Future<void> loadDailyQuote() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final quoteData = await _database.fetchRandomMotivationalQuote();
      if (quoteData != null) {
        _dailyQuote = MockMotivationalQuote.fromMap(quoteData);
      } else {
        _dailyQuote = null;
      }
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load daily quote: ${e.toString()}';
      _dailyQuote = null;
    }
  }

  Future<void> loadQuotesByCategory(String category) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      
      final quotesData = await _database.fetchMotivationalQuotesByCategory(category);
      _quotes = quotesData.map((data) => MockMotivationalQuote.fromMap(data)).toList();
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load quotes for category $category: ${e.toString()}';
      _quotes = [];
    }
  }

  List<String> getAvailableCategories() {
    final categories = _quotes.map((quote) => quote.category).toSet().toList();
    categories.sort();
    return categories;
  }

  List<MockMotivationalQuote> getQuotesByCategory(String category) {
    return _quotes.where((quote) => quote.category == category).toList();
  }

  MockMotivationalQuote? getRandomQuote() {
    if (_quotes.isEmpty) return null;
    return _quotes.first; // Return first for predictable testing
  }

  bool hasQuotes() {
    return _quotes.isNotEmpty;
  }

  int getTotalQuotesCount() {
    return _quotes.length;
  }

  String formatQuoteForDisplay(MockMotivationalQuote quote) {
    return '"${quote.quote}"\n\n— ${quote.author}';
  }

  bool isValidQuote(MockMotivationalQuote quote) {
    return quote.quote.isNotEmpty && 
           quote.author.isNotEmpty && 
           quote.category.isNotEmpty &&
           quote.isActive;
  }

  void clearError() {
    _errorMessage = null;
  }

  void reset() {
    _quotes.clear();
    _dailyQuote = null;
    _isLoading = false;
    _errorMessage = null;
  }

  Map<String, dynamic> getQuotesStatistics() {
    final categoryCount = <String, int>{};
    for (final quote in _quotes) {
      categoryCount[quote.category] = (categoryCount[quote.category] ?? 0) + 1;
    }

    return {
      'total_quotes': _quotes.length,
      'categories': categoryCount.keys.toList(),
      'category_counts': categoryCount,
      'has_daily_quote': _dailyQuote != null,
      'is_loaded': !_isLoading && _errorMessage == null,
    };
  }
}

void main() {
  group('UMP-DM-01: Student can view the motivational quotes on the home page', () {
    late MockDatabase mockDatabase;
    late MotivationalQuotesService quotesService;

    setUp(() {
      mockDatabase = MockDatabase();
      quotesService = MotivationalQuotesService(mockDatabase);
    });

    test('Should load motivational quotes successfully', () async {
      // Seed test data
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'The only way to do great work is to love what you do.',
          'author': 'Steve Jobs',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Believe you can and you\'re halfway there.',
          'author': 'Theodore Roosevelt',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'id': 3,
          'quote': 'Inactive quote for testing',
          'author': 'Test Author',
          'category': 'test',
          'is_active': false, // Should not be loaded
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
      expect(quotesService.quotes.length, 2); // Only active quotes
      expect(quotesService.quotes[0].quote, 'The only way to do great work is to love what you do.');
      expect(quotesService.quotes[0].author, 'Steve Jobs');
      expect(quotesService.quotes[0].category, 'motivation');
      expect(quotesService.quotes[0].isActive, true);
    });

    test('Should load daily quote successfully', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Today is a great day to start something new.',
          'author': 'Anonymous',
          'category': 'daily',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
      ]);

      await quotesService.loadDailyQuote();

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
      expect(quotesService.dailyQuote, isNotNull);
      expect(quotesService.dailyQuote!.quote, 'Today is a great day to start something new.');
      expect(quotesService.dailyQuote!.author, 'Anonymous');
    });

    test('Should handle empty quotes database gracefully', () async {
      mockDatabase.seedMotivationalQuotes([]); // Empty database

      await quotesService.loadMotivationalQuotes();

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
      expect(quotesService.quotes.length, 0);
      expect(quotesService.hasQuotes(), false);
    });

    test('Should handle database connection errors', () async {
      mockDatabase.setShouldThrowError(true);

      await quotesService.loadMotivationalQuotes();

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, contains('Failed to load motivational quotes'));
      expect(quotesService.quotes.length, 0);
    });

    test('Should load quotes by category correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Success is not final, failure is not fatal.',
          'author': 'Winston Churchill',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Believe in yourself and all that you are.',
          'author': 'Christian D. Larson',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'id': 3,
          'quote': 'You are stronger than you think.',
          'author': 'Unknown',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await quotesService.loadQuotesByCategory('confidence');

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
      expect(quotesService.quotes.length, 2); // Only confidence quotes
      expect(quotesService.quotes.every((quote) => quote.category == 'confidence'), true);
    });

    test('Should get available categories correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Test quote 1',
          'author': 'Author 1',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Test quote 2',
          'author': 'Author 2',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'id': 3,
          'quote': 'Test quote 3',
          'author': 'Author 3',
          'category': 'wellness',
          'is_active': true,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();
      final categories = quotesService.getAvailableCategories();

      expect(categories.length, 3);
      expect(categories, containsAll(['confidence', 'motivation', 'wellness']));
      expect(categories, orderedEquals(['confidence', 'motivation', 'wellness'])); // Should be sorted
    });

    test('Should format quote for display correctly', () {
      final quote = MockMotivationalQuote(
        id: 1,
        quote: 'The best time to plant a tree was 20 years ago. The second best time is now.',
        author: 'Chinese Proverb',
        category: 'wisdom',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final formatted = quotesService.formatQuoteForDisplay(quote);
      final expected = '"The best time to plant a tree was 20 years ago. The second best time is now."\n\n— Chinese Proverb';

      expect(formatted, expected);
    });

    test('Should validate quotes correctly', () {
      final validQuote = MockMotivationalQuote(
        id: 1,
        quote: 'Valid quote',
        author: 'Valid Author',
        category: 'valid',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final invalidQuote = MockMotivationalQuote(
        id: 2,
        quote: '', // Empty quote
        author: 'Author',
        category: 'test',
        isActive: true,
        createdAt: DateTime.now(),
      );

      final inactiveQuote = MockMotivationalQuote(
        id: 3,
        quote: 'Inactive quote',
        author: 'Inactive Author',
        category: 'test',
        isActive: false, // Not active
        createdAt: DateTime.now(),
      );

      expect(quotesService.isValidQuote(validQuote), true);
      expect(quotesService.isValidQuote(invalidQuote), false);
      expect(quotesService.isValidQuote(inactiveQuote), false);
    });

    test('Should get quotes by category correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Motivation quote 1',
          'author': 'Author 1',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Motivation quote 2',
          'author': 'Author 2',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'id': 3,
          'quote': 'Confidence quote 1',
          'author': 'Author 3',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();
      
      final motivationQuotes = quotesService.getQuotesByCategory('motivation');
      final confidenceQuotes = quotesService.getQuotesByCategory('confidence');
      final nonExistentQuotes = quotesService.getQuotesByCategory('nonexistent');

      expect(motivationQuotes.length, 2);
      expect(confidenceQuotes.length, 1);
      expect(nonExistentQuotes.length, 0);
      expect(motivationQuotes.every((quote) => quote.category == 'motivation'), true);
    });

    test('Should get random quote correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Random quote for testing',
          'author': 'Test Author',
          'category': 'test',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();
      
      final randomQuote = quotesService.getRandomQuote();

      expect(randomQuote, isNotNull);
      expect(randomQuote!.quote, 'Random quote for testing');
      expect(randomQuote.author, 'Test Author');
    });

    test('Should handle null random quote when no quotes available', () async {
      mockDatabase.seedMotivationalQuotes([]); // Empty database

      await quotesService.loadMotivationalQuotes();
      
      final randomQuote = quotesService.getRandomQuote();

      expect(randomQuote, isNull);
    });

    test('Should get quotes statistics correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Motivation quote 1',
          'author': 'Author 1',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Motivation quote 2',
          'author': 'Author 2',
          'category': 'motivation',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
        {
          'id': 3,
          'quote': 'Confidence quote 1',
          'author': 'Author 3',
          'category': 'confidence',
          'is_active': true,
          'created_at': '2025-01-03T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();
      await quotesService.loadDailyQuote();
      
      final stats = quotesService.getQuotesStatistics();

      expect(stats['total_quotes'], 3);
      expect(stats['categories'], containsAll(['motivation', 'confidence']));
      expect(stats['category_counts']['motivation'], 2);
      expect(stats['category_counts']['confidence'], 1);
      expect(stats['has_daily_quote'], true);
      expect(stats['is_loaded'], true);
    });

    test('Should clear error correctly', () async {
      mockDatabase.setShouldThrowError(true);
      
      await quotesService.loadMotivationalQuotes();
      expect(quotesService.errorMessage, isNotNull);
      
      quotesService.clearError();
      expect(quotesService.errorMessage, isNull);
    });

    test('Should reset service state correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Test quote',
          'author': 'Test Author',
          'category': 'test',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();
      await quotesService.loadDailyQuote();
      
      expect(quotesService.quotes.length, 1);
      expect(quotesService.dailyQuote, isNotNull);
      
      quotesService.reset();
      
      expect(quotesService.quotes.length, 0);
      expect(quotesService.dailyQuote, isNull);
      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
    });

    test('Should handle daily quote loading when no quotes available', () async {
      mockDatabase.seedMotivationalQuotes([]); // Empty database

      await quotesService.loadDailyQuote();

      expect(quotesService.isLoading, false);
      expect(quotesService.errorMessage, isNull);
      expect(quotesService.dailyQuote, isNull);
    });

    test('Should count total quotes correctly', () async {
      mockDatabase.seedMotivationalQuotes([
        {
          'id': 1,
          'quote': 'Quote 1',
          'author': 'Author 1',
          'category': 'test',
          'is_active': true,
          'created_at': '2025-01-01T00:00:00Z',
        },
        {
          'id': 2,
          'quote': 'Quote 2',
          'author': 'Author 2',
          'category': 'test',
          'is_active': true,
          'created_at': '2025-01-02T00:00:00Z',
        },
      ]);

      await quotesService.loadMotivationalQuotes();

      expect(quotesService.getTotalQuotesCount(), 2);
      expect(quotesService.hasQuotes(), true);
    });
  });
}
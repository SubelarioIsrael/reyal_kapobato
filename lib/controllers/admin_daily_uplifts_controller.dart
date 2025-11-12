import 'package:supabase_flutter/supabase_flutter.dart';

// Result classes
class LoadUpliftsResult {
  final bool success;
  final List<Map<String, dynamic>> uplifts;
  final String? errorMessage;

  LoadUpliftsResult({
    required this.success,
    this.uplifts = const [],
    this.errorMessage,
  });
}

class CreateUpliftResult {
  final bool success;
  final String? errorMessage;

  CreateUpliftResult({
    required this.success,
    this.errorMessage,
  });
}

class UpdateUpliftResult {
  final bool success;
  final String? errorMessage;

  UpdateUpliftResult({
    required this.success,
    this.errorMessage,
  });
}

class DeleteUpliftResult {
  final bool success;
  final String? errorMessage;

  DeleteUpliftResult({
    required this.success,
    this.errorMessage,
  });
}

class AdminDailyUpliftsController {
  final _supabase = Supabase.instance.client;

  // Load all daily uplifts
  Future<LoadUpliftsResult> loadUplifts() async {
    try {
      final response = await _supabase
          .from('uplifts')
          .select('*')
          .order('created_at', ascending: false);

      return LoadUpliftsResult(
        success: true,
        uplifts: List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      return LoadUpliftsResult(
        success: false,
        errorMessage: 'Failed to load daily uplifts: ${e.toString()}',
      );
    }
  }

  // Create a new daily uplift
  Future<CreateUpliftResult> createUplift({
    required String quote,
    required String author,
  }) async {
    try {
      // Validate inputs
      final quoteValidation = validateQuote(quote);
      if (quoteValidation != null) {
        return CreateUpliftResult(
          success: false,
          errorMessage: quoteValidation,
        );
      }

      final authorValidation = validateAuthor(author);
      if (authorValidation != null) {
        return CreateUpliftResult(
          success: false,
          errorMessage: authorValidation,
        );
      }

      await _supabase.from('uplifts').insert({
        'quote': quote.trim(),
        'author': author.trim(),
      });

      return CreateUpliftResult(success: true);
    } catch (e) {
      return CreateUpliftResult(
        success: false,
        errorMessage: 'Failed to create daily uplift: ${e.toString()}',
      );
    }
  }

  // Update an existing daily uplift
  Future<UpdateUpliftResult> updateUplift({
    required int upliftId,
    required String quote,
    required String author,
  }) async {
    try {
      // Validate inputs
      final quoteValidation = validateQuote(quote);
      if (quoteValidation != null) {
        return UpdateUpliftResult(
          success: false,
          errorMessage: quoteValidation,
        );
      }

      final authorValidation = validateAuthor(author);
      if (authorValidation != null) {
        return UpdateUpliftResult(
          success: false,
          errorMessage: authorValidation,
        );
      }

      await _supabase
          .from('uplifts')
          .update({
            'quote': quote.trim(),
            'author': author.trim(),
          })
          .eq('uplift_id', upliftId);

      return UpdateUpliftResult(success: true);
    } catch (e) {
      return UpdateUpliftResult(
        success: false,
        errorMessage: 'Failed to update daily uplift: ${e.toString()}',
      );
    }
  }

  // Delete a daily uplift
  Future<DeleteUpliftResult> deleteUplift(int upliftId) async {
    try {
      await _supabase
          .from('uplifts')
          .delete()
          .eq('uplift_id', upliftId);

      return DeleteUpliftResult(success: true);
    } catch (e) {
      return DeleteUpliftResult(
        success: false,
        errorMessage: 'Failed to delete daily uplift: ${e.toString()}',
      );
    }
  }

  // Validators
  String? validateQuote(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a motivational quote';
    }
    if (value.trim().length < 10) {
      return 'Quote must be at least 10 characters long';
    }
    return null;
  }

  String? validateAuthor(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the author name';
    }
    return null;
  }
}

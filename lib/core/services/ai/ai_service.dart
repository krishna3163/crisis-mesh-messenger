import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for handling offline AI inference and structured first-aid guidance
class AIService extends ChangeNotifier {
  final Logger _logger = Logger();
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  // Structured First-Aid Knowledge Base
  static const Map<String, List<String>> _firstAidData = {
    'cpr': [
      '1. Check the scene for safety.',
      '2. Tap the person and shout to see if they respond.',
      '3. Call for emergency help or ask someone else to.',
      '4. Place the heel of one hand in the center of their chest.',
      '5. Push hard and fast: 100-120 compressions per minute.',
      '6. Allow the chest to return to its normal position after each push.'
    ],
    'bleeding': [
      '1. Apply direct pressure to the wound with a clean cloth.',
      '2. Maintain pressure until the bleeding stops.',
      '3. If blood soaks through, add more cloth on top (do not remove original).',
      '4. Elevate the limb above heart level if possible.',
      '5. Apply a bandage to secure the cloth in place.'
    ],
    'choking': [
      '1. Give 5 back blows between the shoulder blades with the heel of your hand.',
      '2. Give 5 abdominal thrusts (Heimlich maneuver).',
      '3. Alternate between 5 blows and 5 thrusts until the object is forced out.'
    ],
    'burn': [
      '1. Cool the burn under cool (not cold) running water for 10-20 minutes.',
      '2. Remove jewelry or tight clothing before the area swells.',
      '3. Cover the burn loosely with a sterile bandage or plastic wrap.',
      '4. Do not pop blisters or apply butter/ointments.'
    ],
    'snake bite': [
      '1. Keep the person calm and still to slow the spread of venom.',
      '2. Remove any jewelry or tight clothing.',
      '3. Position the bitten limb at or below heart level.',
      '4. Clean the wound with soap and water (do not flush with water).',
      '5. Wrap a pressure bandage around the limb, but not too tight.'
    ],
  };

  /// Initialize the AI service
  Future<void> initialize() async {
    _logger.i('Initializing AI knowledge base...');
    // Simulated delay for loading local models or data
    await Future.delayed(const Duration(seconds: 1));
    _isModelLoaded = true;
    notifyListeners();
    _logger.i('AI Assistant ready (Offline Mode).');
  }

  /// Get emergency guidance based on user query
  Future<String> getEmergencyGuidance(String query) async {
    final normalizedQuery = query.toLowerCase();
    _logger.i('AI Query: $normalizedQuery');

    // Simple keyword matching for the offline knowledge base
    for (final key in _firstAidData.keys) {
      if (normalizedQuery.contains(key)) {
        return _firstAidData[key]!.join('\n');
      }
    }

    return "I couldn't find specific instructions for that. Try asking about 'CPR', 'Bleeding', 'Choking', or 'Snake bite'. "
           "Remember to call for emergency professionals if possible.";
  }

  /// Returns the raw list of steps if found, for structured UI display
  List<String>? getStructuredGuidance(String query) {
    final normalizedQuery = query.toLowerCase();
    for (final key in _firstAidData.keys) {
      if (normalizedQuery.contains(key)) {
        return _firstAidData[key];
      }
    }
    return null;
  }
}

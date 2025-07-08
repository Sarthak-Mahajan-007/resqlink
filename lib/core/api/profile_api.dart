import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../models/health_card.dart';

class ProfileApi {
  static final _client = Supabase.instance.client;

  static Future<Profile?> fetchProfile(int userId) async {
    final response = await _client
        .from('profile')
        .select('*, health_card(*)')
        .eq('user_id', userId)
        .maybeSingle();
    if (response == null) return null;
    return Profile.fromJson(response);
  }

  static Future<bool> saveProfile(Profile profile) async {
    // Upsert health card first
    final healthCardData = profile.healthCard?.toJson();
    if (healthCardData == null) return false;
    final healthCardResp = await _client
        .from('health_card')
        .upsert(healthCardData)
        .select()
        .maybeSingle();
    if (healthCardResp == null) return false;
    final healthCard = HealthCard.fromJson(healthCardResp);
    // Upsert profile with health_card_id
    final profileData = profile.toJson();
    profileData['health_card_id'] = healthCard.id;
    profileData.remove('health_card'); // Don't nest
    final profileResp = await _client
        .from('profile')
        .upsert(profileData)
        .select()
        .maybeSingle();
    return profileResp != null;
  }
} 
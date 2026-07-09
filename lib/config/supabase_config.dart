import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String _supabaseUrl = 'https://qrycwbknlcmqikzlwwmx.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_Yk2QK8S727RToTvBW-JggQ_UEui6_5G';

  SupabaseConfig._();

  static Map<String, String> getSupabaseConfig() {
    return {
      'url': _supabaseUrl,
      'anonKey': _supabaseAnonKey,
    };
  }

  static SupabaseClient getSupabaseClient() {
    return SupabaseClient(_supabaseUrl, _supabaseAnonKey);
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
  }
}

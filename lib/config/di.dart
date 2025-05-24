import 'package:get_it/get_it.dart';
import '../services/api_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // Register API Service as a singleton
  getIt.registerSingleton<ApiService>(ApiService());
}

// Extension to make it easier to access the API service
extension GetItExtension on GetIt {
  ApiService get api => get<ApiService>();
}

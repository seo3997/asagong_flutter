import '../../data/api/api_service.dart';
import '../../data/repository/app_repository.dart';
import 'app_service.dart';

class AppServiceProvider {
  static AppServiceProvider? _instance;
  
  late final ApiService apiService;
  late final AppRepository repository;
  late final AppService appService;

  AppServiceProvider._internal({ApiService? apiService}) {
    this.apiService = apiService ?? ApiService();
    repository = AppRepository(apiService: this.apiService);
    appService = AppService(repository: repository);
  }

  static void initialize({ApiService? apiService}) {
    _instance = AppServiceProvider._internal(apiService: apiService);
  }

  static AppService getService() {
    if (_instance == null) {
      initialize();
    }
    return _instance!.appService;
  }
}

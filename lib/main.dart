import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/models/profile_model.dart';
import 'package:flutter_app/Utilities/api_service.dart';
import 'package:flutter_app/Utilities/ai.dart';
import 'package:flutter_app/Utilities/fcm.dart';
import 'package:flutter_app/Authentication/google_auth.dart';
import 'package:flutter_app/screens/home_page.dart';
import 'package:flutter_app/Utilities/bottom_navigation.dart';
import 'package:flutter_app/Utilities/provider.dart';
import 'package:flutter_app/config/app_config.dart';
import 'package:flutter_app/Utilities/firebase_options.dart';
import 'package:flutter_app/Authentication/login.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  final recommendationService = RecommendationService();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Transparent status bar
    statusBarIconBrightness: Brightness.dark, // Dark icons for status bar
    statusBarBrightness: Brightness.light, // Light status bar content
  ));

  WidgetsFlutterBinding.ensureInitialized();
  // Load config before starting the app
  await AppConfig.loadConfig();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseApi.initNotification(); // Initialize Firebase Messaging

  final cartProvider = CartProvider();
  await cartProvider.loadUserData(); // ✅ Load Google User Data

  bool isLoggedIn = await checkUserLoggedIn(); // ✅ Check normal login
  UserDetailsModel? savedUser = await getUserData(); // ✅ Fetch saved user data

  await Permission.storage.request();

  await Permission.manageExternalStorage.request();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await Hive.initFlutter();
  final userId = cartProvider.email ?? cartProvider.useremail ?? '';
  recommendationService.init(userId);

  await FlutterLocalNotificationsPlugin().initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      if (response.payload != null) {
        await OpenFile.open(response.payload!);
      }
    },
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => cartProvider),
        // ✅ Pass existing instance
        Provider<ApiService>(create: (_) => ApiService()),
        Provider<RecommendationService>.value(value: recommendationService),
        // ✅ Add this
      ],
      child: MyApp(isLoggedIn: isLoggedIn, savedUser: savedUser),
    ),
  );
}

// ✅ **Check Login Status (Google or Normal)**
Future<bool> checkUserLoggedIn() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  String? googleUserData = prefs.getString('googleUser');

  return isLoggedIn || googleUserData != null; // ✅ Google OR normal login
}

// ✅ **Retrieve Normal User Data**
Future<UserDetailsModel?> getUserData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String fullName = prefs.getString('full_name') ?? '';
  String email = prefs.getString('email') ?? '';
  String contact = prefs.getString('contact') ?? '';
  String address = prefs.getString('address') ?? '';

  if (fullName.isNotEmpty && email.isNotEmpty) {
    return UserDetailsModel(
      fullName: fullName,
      userId: '',
      image: '',
      email: email,
      contact: contact,
      address: address,
    );
  }
  return null;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final UserDetailsModel? savedUser;

  const MyApp({super.key, required this.isLoggedIn, this.savedUser});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (savedUser != null) {
      cartProvider.setUserDetails(savedUser!); // ✅ Restore normal login data
    }

    bool isGoogleLoggedIn =
        cartProvider.googleProfile != null; // ✅ Restore Google Login

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey.shade50),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          elevation: 0, // Remove shadow
          backgroundColor: Colors.transparent,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomFadeTransitionBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: (isLoggedIn || isGoogleLoggedIn)
          ? Navigation(key: navigationKey)
          : Login(email: '', username: ''),
      routes: {
        "/bottom_navigation": (BuildContext context) => const Navigation(),
      },
    );
  }
}

class CustomFadeTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return Container(
      color: Colors.grey[50], // Background color
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

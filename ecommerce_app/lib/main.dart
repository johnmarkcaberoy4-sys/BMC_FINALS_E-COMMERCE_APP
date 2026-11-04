import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:ecommerce_app/screens/auth_wrapper.dart';
import 'package:ecommerce_app/providers/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart'; // 1. ADD THIS IMPORT - Google Fonts for professional typography
import 'package:flutter/foundation.dart';

const Color kRichBlack = Color(0xFF08060D);
const Color kDarkBlack = Color(0xFF14101C);
const Color kPurple = Color(0xFF7C3AED);
const Color kLightPurple = Color(0xFFA78BFA);
const Color kSurfaceBorder = Color(0xFF39254F);
const Color kTextWhite = Color(0xFFFFFFFF);
const Color kTextLightGrey = Color(0xFFE0D9EA);

void main() async {
  // 1. Preserve splash screen during initialization (Unchanged)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // 2. Initialize Firebase (Unchanged)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Set web persistence (WEB ONLY)
  if (kIsWeb) {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  }

  // 4. --- THIS IS THE FIX ---
  // We manually create the CartProvider instance *before* runApp
  // This fixes the "Stuck Splash Screen" bug by preventing a deadlock during initialization.
  final cartProvider = CartProvider();

  // 5. We call our new initialize method *before* runApp
  // This ensures all logic is ready before Flutter starts building the UI.
  cartProvider.initializeAuthListener();

  // 6. This is the old, buggy code we are replacing:
  /*
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(), // <-- This was the problem
      child: const MyApp(),
    ),
  );
  */

  // 7. This is the NEW code for runApp
  // We use ChangeNotifierProvider.value when we want to provide an object that already exists.
  // The normal ChangeNotifierProvider(create: ...) is used to create a new object.
  runApp(
    // 8. We use ChangeNotifierProvider.value
    ChangeNotifierProvider.value(
      value: cartProvider, // 9. We provide the instance we already created
      child: const MyApp(),
    ),
  );

  // 10. Remove splash screen once app is ready (Unchanged)
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'eCommerce App',

      // 1. --- THIS IS THE NEW, COMPLETE THEME ---
      theme: ThemeData(
        // 2. Set the main color scheme
        //    Black and Red theme for a modern, high-tech look
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPurple,
          brightness: Brightness.dark, // Dark theme for black background
          primary: kPurple,
          onPrimary: Colors.white,
          secondary: kLightPurple,
          surface: kDarkBlack, // Dark surface for cards
          onSurface: kTextWhite, // White text on dark surfaces
        ),
        useMaterial3: true,

        // 3. Set the background color for all screens
        //    Pure black background for that sleek, modern look
        scaffoldBackgroundColor: kRichBlack,

        // 4. --- (FIX) APPLY THE GOOGLE FONT ---
        // This applies "Lato" to all text in the app with white/light colors for visibility
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: kTextWhite, // White text for body
          displayColor: kTextWhite, // White text for headings
        ),

        // 5. --- (FIX) GLOBAL BUTTON STYLE ---
        //    This defines a default style for all ElevatedButtons
        //    All buttons will now be red with rounded corners
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPurple,
            foregroundColor: Colors.white, // White text color
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),

        // 6. --- (FIX) GLOBAL TEXT FIELD STYLE ---
        //    This styles all TextFormFields with rounded corners and red focus border
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kDarkBlack, // Dark background for text fields
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kSurfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kSurfaceBorder),
          ),
          labelStyle: TextStyle(color: kTextLightGrey),
          hintStyle: TextStyle(color: Colors.grey[500]),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLightPurple, width: 2.0),
          ),
        ),

        // 7. --- (FIX) GLOBAL CARD STYLE ---
        //    This makes all Card widgets have rounded corners, soft shadow, and dark color
        cardTheme: CardThemeData(
          elevation: 2, // Slightly more elevation for visibility on black
          color: kDarkBlack, // Dark cards on the black bg
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: kSurfaceBorder, width: 1),
          ),
          // 8. This ensures the images inside the card are rounded
          //    This is key for the "rounded image" fix in ProductCard
          clipBehavior: Clip.antiAlias,
        ),

        // Brand-colored dividers/lines
        dividerTheme: const DividerThemeData(
          color: kSurfaceBorder,
          thickness: 1,
          space: 24,
        ),

        // 9. --- (NEW) GLOBAL APPBAR STYLE ---
        //    Dark AppBar with red accents for a sleek, modern look
        appBarTheme: const AppBarTheme(
          backgroundColor: kRichBlack, // Black AppBar
          foregroundColor: kTextWhite, // Text color
          elevation: 0, // No shadow, modern look
          centerTitle: true,
          iconTheme: IconThemeData(color: kLightPurple),
          actionsIconTheme: IconThemeData(color: kLightPurple),
        ),

        iconTheme: const IconThemeData(
          color: kLightPurple,
        ),
      ),
      // --- END OF NEW THEME ---

      // ✅ Set LoginScreen as the home
      home: const AuthWrapper(),
    );
  }
}

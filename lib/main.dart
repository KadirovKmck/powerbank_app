import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'payment_screen.dart';
import 'success_screen.dart';

void main() => runApp(const PowerbankApp());

class PowerbankApp extends StatelessWidget {
  const PowerbankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Powerbank',
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');
            if (uri.path == '/success') {
              final stationId =
                  uri.queryParameters['stationId'] ?? 'RECH082203000350';
              return MaterialPageRoute(
                  builder: (_) => SuccessScreen(stationId: stationId));
            }
            final stationId =
                uri.queryParameters['stationId'] ?? 'RECH082203000350';
            return MaterialPageRoute(
                builder: (_) => PaymentScreen(stationId: stationId));
          },
          initialRoute: '/',
          theme: ThemeData(
            fontFamily: GoogleFonts.inter().fontFamily,
            useMaterial3: false,
            scaffoldBackgroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';

class SuccessScreen extends StatelessWidget {
  final String stationId;
  const SuccessScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF0A0A0A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 9.h),
              Text(
                'Stay Powered Anytime',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: 1.5.h),
              Text(
                'To return your power bank\n'
                'and keep enjoying our\n'
                'service for free, simply\n'
                'download the app!',
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 17.sp,
                  height: 1.4,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),

              // Градиентная pill-кнопка
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://example.com/app'); // TODO
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 8.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3.5.h),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFC9F8A5),
                        Color(0xFF7BEA6A),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7BEA6A).withOpacity(0.25),
                        blurRadius: 1.5.h,
                        offset: Offset(0, 0.7.h),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Download App',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 1.6.h),

              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 1.w,
                  children: [
                    Text(
                      'Nothing happened?',
                      style: TextStyle(
                        color: const Color(0xFF5F5F5F),
                        fontSize: 12.sp,
                        letterSpacing: 2.0,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@example.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Text(
                        'Contact support',
                        style: TextStyle(
                          color: const Color(0xFF5F5F5F),
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                          decorationThickness: 1.2,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
